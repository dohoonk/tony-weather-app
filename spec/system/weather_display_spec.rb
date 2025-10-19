require "rails_helper"

RSpec.describe "Weather display", type: :system do
  before do
    service = instance_double(
      WeatherService,
      fetch: Forecast.new(
        location: "Portland, OR",
        condition: "Cloudy",
        temperature_c: 12.3,
        temperature_f: 54.1,
        observed_at: Time.zone.parse("2024-03-21 10:30")
      )
    )

    allow(WeatherService).to receive(:new).and_return(service)
    driven_by(:rack_test)
  end

  it "shows the example forecast" do
    visit "/weather"

    expect(page).to have_content("Weather in Portland, OR")
    expect(page).to have_content("Cloudy")
    expect(page).to have_content("54.1°F / 12.3°C")
  end
end