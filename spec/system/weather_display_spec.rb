require "rails_helper"

RSpec.describe "Weather display", type: :system do
  let(:initial_report) do
    WeatherReport.new(
      location: "Portland, OR",
      current: Forecast.new(
        location: "Portland, OR",
        condition: "Cloudy",
        temperature_c: 12.3,
        temperature_f: 54.1,
        observed_at: Time.zone.parse("2024-03-21 10:30"),
        high_temperature_c: 15.0,
        high_temperature_f: 59.0,
        low_temperature_c: 8.0,
        low_temperature_f: 46.4
      ),
      daily: [
        DailyForecast.new(
          date: "2024-03-22",
          condition: "Showers",
          high_temperature_c: 14.0,
          high_temperature_f: 57.2,
          low_temperature_c: 7.0,
          low_temperature_f: 44.6
        )
      ]
    )
  end

  let(:updated_report) do
    WeatherReport.new(
      location: "New York, NY",
      current: Forecast.new(
        location: "New York, NY",
        condition: "Sunny",
        temperature_c: 20.0,
        temperature_f: 68.0,
        observed_at: Time.zone.parse("2024-03-21 13:45"),
        high_temperature_c: 23.0,
        high_temperature_f: 73.4,
        low_temperature_c: 16.0,
        low_temperature_f: 60.8
      ),
      daily: [
        DailyForecast.new(
          date: "2024-03-22",
          condition: "Partly cloudy",
          high_temperature_c: 24.0,
          high_temperature_f: 75.2,
          low_temperature_c: 15.0,
          low_temperature_f: 59.0
        ),
        DailyForecast.new(
          date: "2024-03-23",
          condition: "Rain",
          high_temperature_c: 18.0,
          high_temperature_f: 64.4,
          low_temperature_c: 11.0,
          low_temperature_f: 51.8
        )
      ]
    )
  end

  let(:service) { instance_double(WeatherService) }
  let(:cache) { instance_double(WeatherCache) }

  before do
    driven_by(:rack_test)

    allow(WeatherService).to receive(:new).and_return(service)
    allow(service).to receive(:fetch).and_return(updated_report)

    allow(WeatherCache).to receive(:new).and_return(cache)
    allow(cache).to receive(:write)
    allow(WeatherFetchJob).to receive(:perform_async)

    OmniAuth.config.mock_auth[:google_oauth2] = mock_google_auth(
      info: { name: "System User", email: "system.user@example.com" }
    )
  end

  it "serves cached data and refreshes when the user searches" do
    fresh_cached = WeatherCache::CachedReport.new(
      report: initial_report,
      fetched_at: Time.current
    )

    allow(cache).to receive(:read).with("San Francisco, CA").and_return(fresh_cached)
    allow(cache).to receive(:read).with("New York, NY").and_return(nil)

    visit "/auth/google_oauth2/callback"

    expect(page).to have_current_path(weather_path, ignore_query: true)
    expect(page).to have_content("Weather in Portland, OR")
    expect(page).to have_content("Showers")
    expect(WeatherFetchJob).not_to have_received(:perform_async)

    fill_in "Search for a location", with: "New York, NY"
    click_button "Get weather"

    expect(service).to have_received(:fetch).with(location: "New York, NY")
    expect(cache).to have_received(:write)
      .with("New York, NY", updated_report, fetched_at: kind_of(Time))
    expect(page).to have_content("Weather in New York, NY")
    expect(page).to have_content("Partly cloudy")
    expect(page).to have_content("Rain")
  end
end
