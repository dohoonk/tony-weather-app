require "rails_helper"

RSpec.describe "Weather", type: :request do
    describe "GET /weather" do
        it "renders the stubbed forecast data" do
            get "/weather"

            expect(response).to be_successful
            expect(response.body).to include("San Francisco, CA")
            expect(response.body).to include("Partly cloudy")
            expect(response.body).to include("Temperature")
        end
    end
end