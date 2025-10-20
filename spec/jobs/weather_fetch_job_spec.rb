require "rails_helper"

RSpec.describe WeatherFetchJob do
  let(:service) { instance_double(WeatherService) }
  let(:cache) { instance_double(WeatherCache) }
  let(:forecast) do
    Forecast.new(
      location: "Chicago, IL",
      condition: "Overcast",
      temperature_c: 10.0,
      temperature_f: 50.0,
      observed_at: Time.zone.parse("2024-03-21 08:00")
    )
  end

  before do
    allow(WeatherService).to receive(:new).and_return(service)
    allow(WeatherCache).to receive(:new).and_return(cache)
  end

  it "writes fresh data on success" do
    expect(service).to receive(:fetch).with(location: "Chicago, IL").and_return(forecast)
    expect(cache).to receive(:write).with("Chicago, IL", forecast)

    described_class.new.perform("Chicago, IL")
  end

  it "suprress WeatherService errors" do
    expect(service).to receive(:fetch).and_raise(WeatherService::Error, "timeout")
    expect(cache).not_to receive(:write)

    expect { described_class.new.perform("Chicago, IL") }.not_to raise_error
  end
end
