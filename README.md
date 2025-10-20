# README

# WeatherForecast

Rails 7 application that surfaces weather data via a typed address search. Authenticated users sign in with Google OAuth, submit an address, and the app fetches the current forecast from WeatherAPI.

## Setup

```bash
bundle install
bin/rails db:setup
```

Create a `.env` file with:

```
WEATHERAPI_KEY=your_api_key
GOOGLE_CLIENT_ID=your_client_id
GOOGLE_CLIENT_SECRET=your_client_secret
```

Install JavaScript dependencies for jsbundling-rails:

```bash
npm install
```

Run Sidekiq for background refreshes:

```bash
bundle exec sidekiq -q
```

## Running Tests

```bash
bundle exec rspec
```

## Address Search Overview

- `AddressQuery` form object (see `app/forms/address_query.rb`) trims user input and exposes a normalized value.
- `WeatherController#show` instantiates `AddressQuery` and passes `address_query.value || default_location` to `WeatherService`.
- `_search_form.html.erb` binds the typed value so the form retains state after submission.
- Request and system specs exercise manual address entry via the service layer.

For a deeper breakdown of responsibilities see `ARCHITECTURE.md`.

## Caching & Background Refresh

- `WeatherCache` persists serialized forecasts in Redis (`REDIS_URL`, defaults to `redis://127.0.0.1:6379/0`).
- `WeatherController#show` serves cached data immediately; entries older than five minutes enqueue `WeatherFetchJob` for refresh.
- `WeatherFetchJob` runs via Sidekiq and rewrites the cache with fresh data.
- Run Sidekiq locally with `bundle exec sidekiq -q weather`.


## Object Decomposition

- **Landing vs. Dashboard** – `HomeController` renders the public landing experience; `WeatherController#show` powers the authenticated dashboard, coordinating cache reads, live fetches, stale detection, and fallbacks.
- **Form object** – `AddressQuery` in `app/forms` trims and normalizes the submitted address before it hits the service layer.
- **Weather pipeline** – `WeatherService` combines `WeatherClient` (Faraday wrapper) with value objects (`WeatherReport`, `Forecast`, `DailyForecast`) that format temperatures and timestamps for the view.
- **Caching layer** – `WeatherCache` encapsulates Redis serialization, returning a `CachedReport` struct that exposes both the data and its freshness timestamp.
- **Background processing** – `WeatherFetchJob` (Sidekiq) asynchronously refreshes cache entries so requests stay responsive even when WeatherAPI is slow.

## Design Patterns

- **Service objects** – `WeatherService` and `WeatherClient` isolate third-party API interactions and transformation logic; this keeps controllers thin and tests direct.
- **Form object** – `AddressQuery` follows the form-object pattern, handling normalization/validation without bloating the controller.
- **Value objects** – `WeatherReport`, `Forecast`, and `DailyForecast` behave like immutable view models.
- **Cache facade** – `WeatherCache` acts as a facade around Redis, presenting a cohesive interface and hiding storage details from callers.
- **Worker queue** – `WeatherFetchJob` implements a worker pattern, offloading expensive refreshes to Sidekiq so HTTP requests return quickly.

## Scalability Considerations & Trade-offs

- **Cache TTL vs. freshness** – Forecasts stay cached for 30 minutes and refresh when they age past five; this lowers WeatherAPI usage under load but tolerates brief staleness for rapidly changing conditions.
- **Key normalization** – Address-based keys support free-form search but reduce cache hit rate (e.g., “Seattle” vs “Seattle, WA”); moving to ZIP or coordinate keys increases reuse at the cost of extra validation/geocoding.
- **Background throughput** – With Sidekiq, refreshes queue safely during spikes; scaling requires monitoring queue depth and workers so stale data doesn’t linger.
- **External dependency limits** – WeatherAPI rate limits bound total traffic; if usage grows, consider multi-location endpoints or plan upgrades.
- **Asset pipeline** – JS bundling relies on esbuild via `jsbundling-rails`; as bundles grow, shift static assets behind a CDN and explore code-splitting to keep builds predictable.


## Scope Limitations

- **Cache keys mirror the submitted address** – Cached forecasts are indexed by the normalized city/state string (`address.parameterize`). Two users typing the same location differently (“Seattle, WA” vs “Seattle”) will bypass each other’s cache entry.
- **ZIP-based caching needs extra plumbing** – Switching to ZIP keys would require (1) a lightweight geocoding lookup to derive a postal code when the input lacks one and (2) validation to block ambiguous entries (e.g., “Seattle”) that cannot be resolved to a single ZIP.
- **Trade-offs today**
  - *Pro*: Accepting free-form city/state lets users search broadly without knowing an exact ZIP.
  - *Con*: We never persist the postal code, so cache reuse can not rely on ZIP.
- **Rate limiting deferred** – The current build relies on WeatherAPI’s own quotas and our Redis cache to absorb spikes. If we anticipate heavy user traffic, we should add application-level throttling (Rack::Attack or an API gateway) to protect upstream services and stop runaway request bursts.
