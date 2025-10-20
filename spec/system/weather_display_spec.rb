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

  before do
    driven_by(:rack_test)

    allow(WeatherService).to receive(:new).and_return(service)
    allow(service).to receive(:fetch).and_return(initial_forecast, updated_forecast)

    OmniAuth.config.mock_auth[:google_oauth2] = mock_google_auth(
      info: {
        name: "System User",
        email: "system.user@example.com"
      }
    )
  end

  it "allows a signed-in user to search for a new address" do
    visit "/auth/google_oauth2/callback"

    expect(page).to have_current_path(weather_path, ignore_query: true)
    expect(page).to have_content("Weather in Portland, OR")

    fill_in "Search for a location", with: "New York, NY"
    click_button "Get weather"

    expect(service).to have_received(:fetch).with(location: "New York, NY")
    expect(page).to have_content("Weather in New York, NY")
    expect(page).to have_content("Sunny")
  end
end
