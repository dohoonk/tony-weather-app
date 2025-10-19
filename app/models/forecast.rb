class Forecast
    attr_reader :location, :condition, :temperature_c, :temperature_f, :observed_at

    def initialize(location:, condition:, temperature_c:, temperature_f:, observed_at:)
        @location = location
        @condition = condition
        @temperature_c = temperature_c
        @temperature_f = temperature_f
        @observed_at = observed_at
    end

    def self.example
        new(
            location: "San Francisco, CA",
            condition: "Partly cloudy",
            temperature_c: 24.0,
            temperature_f: 64.4,
            observed_at: Time.zone.parse("2000-01-12 08:08:01")
          )
    end

    def formatted_observed_at
        observed_at.strftime("%b %e, %Y at %l:%M %p %Z")
    end

    def formatted_temperature
        "#{temperature_f.round(1)}°F / #{temperature_c.round(1)}°C"
    end

end