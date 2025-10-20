require "rails_helper"

RSpec.describe "Weather display", type: :system do
  let(:initial_forecast) do
    Forecast.new(
      location: "Portland, OR",
      condition: "Cloudy",
      temperature_c: 12.3,
      temperature_f: 54.1,
      observed_at: Time.zone.parse("2024-03-21 10:30")
    )
  end

  let(:updated_forecast) do
    Forecast.new(
      location: "New York, NY",
      condition: "Sunny",
      temperature_c: 20.0,
      temperature_f: 68.0,
      observed_at: Time.zone.parse("2024-03-21 13:45")
    )
  end

  let(:service) { instance_double(WeatherService) }
  let(:cache) { instance_double(WeatherCache) }

  before do
    driven_by(:rack_test)

    allow(WeatherService).to receive(:new).and_return(service)
    allow(service).to receive(:fetch).and_return(updated_forecast)

    allow(WeatherCache).to receive(:new).and_return(cache)
    allow(cache).to receive(:write)
    allow(WeatherFetchJob).to receive(:perform_async)

    OmniAuth.config.mock_auth[:google_oauth2] = mock_google_auth(
      info: {
        name: "System User",
        email: "system.user@example.com"
      }
    )
  end

  it "serves cached data and refreshes when the user searches" do
    fresh_cached = WeatherCache::CachedForecast.new(
      forecast: initial_forecast,
      fetched_at: Time.current
    )

    allow(cache).to receive(:read).with("San Francisco, CA").and_return(fresh_cached)
    allow(cache).to receive(:read).with("New York, NY").and_return(nil)

    visit "/auth/google_oauth2/callback"

    expect(page).to have_current_path(weather_path, ignore_query: true)
    expect(page).to have_content("Weather in Portland, OR")
    expect(WeatherFetchJob).not_to have_received(:perform_async)

    fill_in "Search for a location", with: "New York, NY"
    click_button "Get weather"

    expect(service).to have_received(:fetch).with(location: "New York, NY")
    expect(cache).to have_received(:write).with("New York, NY", updated_forecast, fetched_at: kind_of(Time))
    expect(page).to have_content("Weather in New York, NY")
    expect(page).to have_content("Sunny")
  end
end
