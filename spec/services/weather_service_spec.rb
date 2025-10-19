require "rails_helper"

RSpec.describe WeatherService do
  let(:location) { "San Francisco, CA" }
  let(:client) { instance_double(WeatherClient) }
  let(:service) { described_class.new(client:) }

  describe "#fetch" do
    context "when the client succeeds" do
      let(:api_response) do
        {
          "location" => {
            "name" => "San Francisco",
            "region" => "California",
            "country" => "USA",
            "localtime" => "2024-03-20 09:00"
          },
          "current" => {
            "temp_c" => 18.0,
            "temp_f" => 64.4,
            "condition" => { "text" => "Partly cloudy" },
            "last_updated" => "2024-03-20 08:45"
          }
        }
      end

      before do
        allow(client).to receive(:current)
          .with(location:)
          .and_return(api_response)
      end

      it "returns a Forecast object" do
        forecast = service.fetch(location:)

        expect(forecast).to be_a(Forecast)
        expect(forecast.location).to eq("San Francisco, California, USA")
        expect(forecast.condition).to eq("Partly cloudy")
        expect(forecast.temperature_f).to eq(64.4)
      end
    end

    context "when the client raises an error" do
      before do
        allow(client).to receive(:current)
          .and_raise(WeatherClient::Error, "Error")
      end

      it "raises a WeatherService::Error" do
        expect { service.fetch(location:) }
          .to raise_error(WeatherService::Error, /Weather service failed/)
      end
    end
  end
end
