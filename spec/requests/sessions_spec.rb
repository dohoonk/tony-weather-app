require "rails_helper"

RSpec.describe "Sessions", type: :request do
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

  describe "GET /auth/google_oauth2/callback" do
    it "stores the user in the session and redirects to weather" do
      OmniAuth.config.mock_auth[:google_oauth2] = mock_google_auth(
        info: {
          name: "Jane Doe",
          email: "jane.doe@example.com",
          image: "https://example.com/jane.png"
        }
      )

      get "/auth/google_oauth2/callback"

      expect(session[:user]).to include(
        uid: "12345",
        name: "Jane Doe",
        email: "jane.doe@example.com"
      )
      expect(response).to redirect_to(weather_path)
      expect(flash[:notice]).to eq("Signed in successfully.")
    end
  end

  describe "DELETE /logout" do
    it "clears the user session and redirects to weather" do
      get "/auth/google_oauth2/callback"
      delete "/logout"

      expect(session[:user]).to be_nil
      expect(response).to redirect_to(root_path)
      expect(flash[:notice]).to eq("Signed out successfully.")
    end
  end

  describe "GET /auth/failure" do
    it "redirects to weather with an alert" do
      get "/auth/failure"

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("Authentication failed.")
    end
  end
end
