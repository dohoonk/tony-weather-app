require "rails_helper"

RSpec.describe WeatherCache do
  include ActiveSupport::Testing::TimeHelpers
  let(:redis) { instance_double(Redis) }
  let(:cache) { described_class.new(redis:) }
  let(:location) { "San Francisco, CA" }
  let(:forecast) do
    Forecast.new(
      location: location,
      condition: "Sunny",
      temperature_c: 18.5,
      temperature_f: 65.3,
      observed_at: Time.zone.parse("2024-03-21 10:00")
    )
  end

  describe "#write" do
    it "serializes the forecast and stores it with a TTL" do
      travel_to Time.zone.parse("2024-03-21 10:05:00Z") do
        expect(redis).to receive(:set) do |key, payload, ex:|
          expect(key).to include("weather:forecast")
          data = JSON.parse(payload)
          expect(data["forecast"]["location"]).to eq("San Francisco, CA")
          expect(data["fetched_at"]).to eq("2024-03-21T10:05:00Z")
          expect(ex).to eq(described_class::TTL)
        end

        cache.write(location, forecast, fetched_at: Time.zone.parse("2024-03-21 10:05:00Z"))
      end
    end
  end

  describe "#read" do
    let(:stored_payload) do
      {
        "forecast" => {
          "location" => location,
          "condition" => "Sunny",
          "temperature_c" => 18.5,
          "temperature_f" => 65.3,
          "observed_at" => "2024-03-21T10:00:00Z"
        },
        "fetched_at" => "2024-03-21T10:05:00Z"
      }.to_json
    end

    it "rehydrates a forecast with staleness helpers" do
      allow(redis).to receive(:get).and_return(stored_payload)

      travel_to Time.zone.parse("2024-03-21 10:06:00Z") do
        cached = cache.read(location)
        expect(cached.forecast.location).to eq("San Francisco, CA")
        expect(cached.forecast.condition).to eq("Sunny")
        expect(cached.fetched_at).to eq(Time.zone.parse("2024-03-21T10:05:00Z"))
        expect(cached.stale?(threshold: 1.minute)).to be true
        expect(cached.stale?(threshold: 1.hour)).to be false
      end
    end

    it "returns nil when missing" do
      allow(redis).to receive(:get).and_return(nil)
      expect(cache.read(location)).to be_nil
    end
  end
end
