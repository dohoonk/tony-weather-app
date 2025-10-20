require "rails_helper"

RSpec.describe "Weather", type: :request do
  describe "GET /weather" do
    it "renders the fetched forecast data", :vcr do
      get "/auth/google_oauth2/callback"
      get "/weather"

      expect(response).to be_successful
      expect(response.body).to include("Condition:")
      expect(response.body).to include("Temperature:")
      expect(response.body).to include("Observed:")
    end

    it "forwards the normalized address to the weather service" do
      forecast = Forecast.new(
        location: "New York, NY",
        condition: "Sunny",
        temperature_c: 20.0,
        temperature_f: 68.0,
        observed_at: Time.zone.parse("2024-03-21 11:00")
      )

      service = instance_double(WeatherService, fetch: forecast)
      allow(WeatherService).to receive(:new).and_return(service)

      get "/auth/google_oauth2/callback"
      get "/weather", params: { address: "  New York, NY  " }

      expect(service).to have_received(:fetch).with(location: "New York, NY")
      expect(response.body).to include("Weather in New York, NY")
    end
  end
end
