require 'rails_helper'

RSpec.describe "Healthchecks", type: :request do
  let(:forecast) do
    Forecast.new(
      location: "Portland, OR",
      condition: "Cloudy",
      temperature_c: 12.3,
      temperature_f: 54.1,
      observed_at: Time.zone.parse("2024-03-21 10:30")
    )
  end

  before do
    service = instance_double(WeatherService, fetch: forecast)
    allow(WeatherService).to receive(:new).and_return(service)
  end
  
  describe "GET /index" do
    it "returns a http success" do
      get "/health"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /" do
    it "returns a http success" do
      get "/"
      expect(response).to have_http_status(:ok)
    end
  end
end
