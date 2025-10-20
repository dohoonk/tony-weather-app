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
            "condition" => { "text" => "Partly cloudy", "icon" => "//cdn.weatherapi.com/icon.png" },
            "last_updated" => "2024-03-20 08:45"
          },
          "forecast" => {
            "forecastday" => [
              {
                "date" => "2024-03-20",
                "day" => {
                  "maxtemp_c" => 20.0,
                  "maxtemp_f" => 68.0,
                  "mintemp_c" => 12.0,
                  "mintemp_f" => 53.6,
                  "condition" => { "text" => "Cloudy", "icon" => "//cdn.weatherapi.com/cloudy.png" }
                }
              },
              {
                "date" => "2024-03-21",
                "day" => {
                  "maxtemp_c" => 22.0,
                  "maxtemp_f" => 71.6,
                  "mintemp_c" => 14.0,
                  "mintemp_f" => 57.2,
                  "condition" => { "text" => "Sunny", "icon" => "//cdn.weatherapi.com/sunny.png" }
                }
              }
            ]
          }
        }
      end

      before do
        allow(client).to receive(:forecast)
          .with(location: location, days: WeatherService::FORECAST_DAYS)
          .and_return(api_response)
      end

      it "returns a WeatherReport with current and daily forecasts" do
        report = service.fetch(location:)

        expect(report).to be_a(WeatherReport)
        expect(report.location).to eq("San Francisco, California, USA")

        current = report.current
        expect(current).to be_a(Forecast)
        expect(current.condition).to eq("Partly cloudy")
        expect(current.temperature_f).to eq(64.4)
        expect(current.high_temperature_f).to eq(68.0)
        expect(current.low_temperature_f).to eq(53.6)

        expect(report.daily.size).to eq(2)
        expect(report.daily.first).to be_a(DailyForecast)
        expect(report.daily.first.condition).to eq("Cloudy")
      end
    end

    context "when the client raises an error" do
      before do
        allow(client).to receive(:forecast)
          .and_raise(WeatherClient::Error, "Error")
      end

      it "raises a WeatherService::Error" do
        expect { service.fetch(location:) }
          .to raise_error(WeatherService::Error, /Weather service failed/)
      end
    end
  end
end
