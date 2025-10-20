class WeatherClient
  API_ENDPOINT = "https://api.weatherapi.com/v1/forecast.json"
  DEFAULT_DAYS = 5

  # Raised for any downstream HTTP or parsing issues so callers can rescue uniformly
  class Error < StandardError; end

  # Accept Faraday connection injection to help with testing
  def initialize(api_key:, connection: Faraday.new)
    @api_key = api_key
    @connection = connection
  end

  def forecast(location:, days: DEFAULT_DAYS)
    response = request_forecast(location:, days:)

    raise Error, "Weather API request failed with status #{response.status}" unless response.success?

    parse_body(response.body)
  rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
    raise Error, "Weather API request failed: #{e.message}"
  end

  private

  attr_reader :api_key, :connection

  def request_forecast(location:, days:)
    connection.get(API_ENDPOINT, default_params.merge(q: location, days: days))
  end

  def default_params
    { key: api_key }
  end

  def parse_body(body)
    JSON.parse(body)
  rescue JSON::ParserError => e
    raise Error, "Weather API returned invalid JSON: #{e.message}"
  end
end
