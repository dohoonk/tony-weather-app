class Forecast
  attr_reader :location,
              :condition,
              :temperature_c,
              :temperature_f,
              :observed_at,
              :high_temperature_c,
              :high_temperature_f,
              :low_temperature_c,
              :low_temperature_f,
              :icon_url

  def initialize(location:,
                 condition:,
                 temperature_c:,
                 temperature_f:,
                 observed_at:,
                 high_temperature_c: nil,
                 high_temperature_f: nil,
                 low_temperature_c: nil,
                 low_temperature_f: nil,
                 icon_url: nil)
    @location = location
    @condition = condition
    @temperature_c = temperature_c
    @temperature_f = temperature_f
    @observed_at = observed_at
    @high_temperature_c = high_temperature_c
    @high_temperature_f = high_temperature_f
    @low_temperature_c = low_temperature_c
    @low_temperature_f = low_temperature_f
    @icon_url = icon_url
  end

  def self.example
    new(
      location: "San Francisco, CA",
      condition: "Partly cloudy",
      temperature_c: 24.0,
      temperature_f: 75.2,
      observed_at: Time.zone.parse("2000-01-12 08:08:01"),
      high_temperature_c: 28.0,
      high_temperature_f: 82.4,
      low_temperature_c: 18.0,
      low_temperature_f: 64.4,
      icon_url: "https://example.com/icon.png"
    )
  end

  def formatted_observed_at
    observed_at.strftime("%b %e, %Y at %l:%M %p %Z")
  end

  def formatted_temperature
    "#{temperature_f.round(1)}°F / #{temperature_c.round(1)}°C"
  end

  def formatted_high_low
    return unless high_temperature_f && low_temperature_f

    "H: #{high_temperature_f.round(1)}°F / L: #{low_temperature_f.round(1)}°F"
  end
end
