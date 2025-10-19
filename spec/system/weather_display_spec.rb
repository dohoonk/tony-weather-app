require "rails_helper"

RSpec.describe "Weather display", type: :system do
    before { driven_by(:rack_test) }
    it "shows the example forecast" do
        visit "/weather"

        expect(page).to have_content("Weather in San Francisco, CA")
        expect(page).to have_content("Partly cloudy")
        expect(page).to have_content("Temperature:")
        expect(page).to have_content("Observed:")
    end
end