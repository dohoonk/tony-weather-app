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
