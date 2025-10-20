## Weather Forecast – Address Flow

- `WeatherController#show`
  - Instantiates `AddressQuery` and normalizes the location.
  - Reads from `WeatherCache`; serves cached data immediately when present.
  - Enqueues `WeatherFetchJob` if the cached entry is stale (older than 5 minutes).
  - Falls back to live fetch via `WeatherService` when cache misses occur and writes the result back to cache.

- `AddressQuery` (app/forms)
  - Coerces raw input to string, trims whitespace, and exposes `value` / `present?`.
  - Keeps normalization logic isolated for easy validation or future extensions.

- `WeatherService`
  - Receives the normalized location string and calls `WeatherClient`.
  - Handles downstream failures and raises domain-specific errors.

- `WeatherCache`
  - Stores serialized forecasts in Redis per normalized location.
  - Exposes `CachedForecast` objects with staleness helpers.

- `WeatherFetchJob`
  - Sidekiq job triggered when cached data is missing or stale.
  - Fetches fresh data via `WeatherService` and rewrites the cache.

- Views
  - `_search_form.html.erb` renders the address input and retains the typed value via `@address_query.value`.
  - `show.html.erb` renders the search form and forecast details.

- Tests
  - `spec/forms/address_query_spec.rb` covers normalization semantics.
  - `spec/requests/weather_controller_spec.rb` asserts cache usage and stale refresh behavior.
  - `spec/services/weather_cache_spec.rb` covers serialization/staleness.
  - `spec/jobs/weather_fetch_job_spec.rb` covers the background refresh job.
  - `spec/system/weather_display_spec.rb` exercises the cached flow end-to-end.
