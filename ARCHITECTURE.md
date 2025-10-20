## Weather Forecast – Address Flow

- `WeatherController#show`
  - Instantiates `AddressQuery` with `params[:address]`.
  - Resolves `location` via `address_query.value || default_location`.
  - Delegates to `WeatherService#fetch(location:)` and stores the result in `@forecast`.

- `AddressQuery` (app/forms)
  - Coerces raw input to string, trims whitespace, and exposes `value` / `present?`.
  - Keeps normalization logic isolated for easy validation or future extensions.

- `WeatherService`
  - Receives the normalized location string and calls `WeatherClient`.
  - Handles downstream failures and raises domain-specific errors.

- Views
  - `_search_form.html.erb` renders the address input and retains the typed value via `@address_query.value`.
  - `show.html.erb` renders the search form and forecast details.

- Tests
  - `spec/forms/address_query_spec.rb` covers normalization semantics.
  - `spec/requests/weather_controller_spec.rb` ensures the service receives the cleaned address.
  - `spec/system/weather_display_spec.rb` exercises the manual search flow through the UI.
