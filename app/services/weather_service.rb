class WeatherService
  class Error < StandardError; end

  def initialize(client: default_client)
    @client = client
  end

  def fetch(location:)
    response = client.current(location:)

    Forecast.new(
      location: formatted_location(response),
      condition: response.dig("current", "condition", "text"),
      temperature_c: response.dig("current", "temp_c"),
      temperature_f: response.dig("current", "temp_f"),
      observed_at: parse_time(response.dig("current", "last_updated"))
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

  def formatted_location(response)
    name = response.dig("location", "name")
    region = response.dig("location", "region")
    country = response.dig("location", "country")

    [name, region, country].compact.join(", ")
  end

  def parse_time(value)
    Time.zone.parse(value)
  rescue ArgumentError, TypeError
    nil
  end
end