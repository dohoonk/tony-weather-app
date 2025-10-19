require 'rails_helper'

RSpec.describe "Healthchecks", type: :request do
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
