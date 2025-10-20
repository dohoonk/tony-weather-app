require "rails_helper"

RSpec.describe "Weather", type: :request do
  let(:cache) { instance_double(WeatherCache) }

  before do
    allow(WeatherCache).to receive(:new).and_return(cache)
    allow(cache).to receive(:write)
  end

  describe "GET /weather" do
    it "renders uncached results and stores them", :vcr do
      allow(cache).to receive(:read).and_return(nil)
      allow(WeatherFetchJob).to receive(:perform_async)

      get "/auth/google_oauth2/callback"
      get "/weather"

      expect(response).to be_successful
      expect(cache).to have_received(:write).with("San Francisco, CA", kind_of(Forecast), fetched_at: kind_of(Time))
      expect(WeatherFetchJob).not_to have_received(:perform_async)
    end

    it "serves cached weather and enqueues refresh when stale" do
      forecast = Forecast.new(
        location: "Los Angeles, CA",
        condition: "Hazy",
        temperature_c: 22.0,
        temperature_f: 71.6,
        observed_at: Time.zone.parse("2024-03-21 09:00")
      )

      cached = WeatherCache::CachedForecast.new(
        forecast: forecast,
        fetched_at: 1.hour.ago
      )

      allow(cache).to receive(:read).and_return(cached)
      allow(WeatherFetchJob).to receive(:perform_async)

      get "/auth/google_oauth2/callback"
      get "/weather", params: { address: "Los Angeles, CA" }

      expect(response.body).to include("Weather in Los Angeles, CA")
      expect(WeatherFetchJob).to have_received(:perform_async).with("Los Angeles, CA")
      expect(cache).not_to have_received(:write)
    end
  end
end
