require "rails_helper"

RSpec.describe "Authentication flow", type: :system do
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
    driven_by(:rack_test)

    service = instance_double(WeatherService, fetch: forecast)
    allow(WeatherService).to receive(:new).and_return(service)

    OmniAuth.config.mock_auth[:google_oauth2] = mock_google_auth(
      info: {
        name: "System User",
        email: "system.user@example.com",
        image: "https://example.com/system.png"
      }
    )
  end

  it "allows a user to sign in and sign out" do
    visit root_path

    expect(page).to have_link("Sign in with Google")

    click_link "Sign in with Google", match: :first

    expect(page).to have_content("Signed in successfully.")
    expect(page).to have_content("Signed in as")
    expect(page).to have_content("System User")
    expect(page).to have_content("Weather in Portland, OR")

    click_button "Sign out"

    expect(page).to have_content("Signed out successfully.")
    expect(page).to have_link("Sign in with Google")
  end
end
