require "rails_helper"

RSpec.describe "Weather", type: :request do
    describe "GET /weather" do
      it "renders the fetched forecast data", :vcr do
          get "/weather"

          expect(response).to be_successful
          expect(response.body).to include("Condition:")
          expect(response.body).to include("Temperature:")
          expect(response.body).to include("Observed:")
      end
   end
end
