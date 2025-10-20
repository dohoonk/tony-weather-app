require "date"

class DailyForecast
  attr_reader :date,
              :condition,
              :high_temperature_c,
              :high_temperature_f,
              :low_temperature_c,
              :low_temperature_f,
              :icon_url

  def initialize(date:,
                 condition:,
                 high_temperature_c:,
                 high_temperature_f:,
                 low_temperature_c:,
                 low_temperature_f:,
                 icon_url: nil)
    @date = date
    @condition = condition
    @high_temperature_c = high_temperature_c
    @high_temperature_f = high_temperature_f
    @low_temperature_c = low_temperature_c
    @low_temperature_f = low_temperature_f
    @icon_url = icon_url
  end

  def formatted_date
    Date.parse(date.to_s).strftime("%a, %b %e")
  end

  def formatted_high_low
    "#{high_temperature_f.round(1)}°F / #{low_temperature_f.round(1)}°F"
  end
end
