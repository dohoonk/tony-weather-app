require "rails_helper"

RSpec.describe WeatherClient do
  let(:api_key) { "test-key" }
  let(:client) { described_class.new(api_key:) }
  let(:location) { "San Francisco, CA" }
  let(:endpoint) { "https://api.weatherapi.com/v1/forecast.json" }
  let(:query_params) { { key: api_key, q: location, days: 5 } }

  describe "#forecast" do
    context "when the API returns success" do
      let(:response_body) do
        {
          location: { name: "San Francisco", region: "California", country: "USA", localtime: "2024-03-20 09:00" },
          forecast: {
            temp_c: 18.0,
            temp_f: 64.4,
            condition: { text: "Partly cloudy" },
            last_updated: "2024-03-20 08:45"
          }
        }.to_json
      end

      before do
        stub_request(:get, endpoint)
          .with(query: query_params)
          .to_return(status: 200, body: response_body, headers: { "Content-Type" => "application/json" })
      end

      it "returns parsed JSON data" do
        result = client.forecast(location:)

        expect(result.dig("location", "name")).to eq("San Francisco")
        expect(result.dig("forecast", "temp_f")).to eq(64.4)
        expect(result.dig("forecast", "condition", "text")).to eq("Partly cloudy")
      end
    end

    context "when the API returns a client error" do
      before do
        stub_request(:get, endpoint)
          .with(query: query_params)
          .to_return(status: 404, body: { error: { message: "No matching location found." } }.to_json)
      end

      it "raises a WeatherClient::Error" do
        expect { client.forecast(location:) }
        .to raise_error(WeatherClient::Error, /Weather API request failed/)
      end
    end

    context "when the request times out" do
      before do
        stub_request(:get, endpoint)
          .with(query: query_params)
          .to_timeout
      end

      it "raises a WeatherClient::Error" do
        expect { client.forecast(location:) }
          .to raise_error(WeatherClient::Error, /Weather API request failed/)
      end
    end
  end
end
