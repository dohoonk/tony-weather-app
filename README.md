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

## Scope Limitations

- **Cache keys mirror the submitted address** – Cached forecasts are indexed by the normalized city/state string (`address.parameterize`). Two users typing the same location differently (“Seattle, WA” vs “Seattle”) will bypass each other’s cache entry.
- **ZIP-based caching needs extra plumbing** – Switching to ZIP keys would require (1) a lightweight geocoding lookup to derive a postal code when the input lacks one and (2) validation to block ambiguous entries (e.g., “Seattle”) that cannot be resolved to a single ZIP.
- **Trade-offs today**
  - *Pro*: Accepting free-form city/state lets users search broadly without knowing an exact ZIP.
  - *Con*: We never persist the postal code, so cache reuse can not rely on ZIP.
