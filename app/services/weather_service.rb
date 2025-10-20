class WeatherService
  FORECAST_DAYS = 5

  class Error < StandardError; end

  def initialize(client: default_client)
    @client = client
  end

  def fetch(location:)
    data = client.forecast(location: location, days: FORECAST_DAYS)

    WeatherReport.new(
      location: formatted_location(data.fetch("location")),
      current: build_current_forecast(data),
      daily: build_daily_forecasts(data)
    )
  rescue WeatherClient::Error => e
    raise Error, "Weather service failed: #{e.message}"
  end

  private

  attr_reader :client

  def default_client
    api_key = ENV.fetch("WEATHERAPI_KEY")
    WeatherClient.new(api_key:)
  end

  def formatted_location(location_hash)
    [location_hash["name"], location_hash["region"], location_hash["country"]].compact.join(", ")
  end

  def build_current_forecast(data)
    current = data.fetch("current")
    today = data.dig("forecast", "forecastday")&.first&.fetch("day", {}) || {}

    Forecast.new(
      location: formatted_location(data.fetch("location")),
      condition: current.dig("condition", "text"),
      temperature_c: current["temp_c"],
      temperature_f: current["temp_f"],
      observed_at: parse_time(current["last_updated"]),
      high_temperature_c: today["maxtemp_c"],
      high_temperature_f: today["maxtemp_f"],
      low_temperature_c: today["mintemp_c"],
      low_temperature_f: today["mintemp_f"],
      icon_url: current.dig("condition", "icon")
    )
  end

  def build_daily_forecasts(data)
    days = data.dig("forecast", "forecastday") || []

    days.map do |day|
      info = day.fetch("day", {})
      DailyForecast.new(
        date: day["date"],
        condition: info.dig("condition", "text"),
        high_temperature_c: info["maxtemp_c"],
        high_temperature_f: info["maxtemp_f"],
        low_temperature_c: info["mintemp_c"],
        low_temperature_f: info["mintemp_f"],
        icon_url: info.dig("condition", "icon")
      )
    end
  end

  def parse_time(value)
    Time.zone.parse(value)
  rescue ArgumentError, TypeError
    nil
  end
end
