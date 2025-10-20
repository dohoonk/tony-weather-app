class WeatherCache
  TTL = 30.minutes
  # We still serve cached data immediately, but after 5 minutes we treat it as stale—that signals we should queue a background refresh.
  STALE_AFTER = 5.minutes
  KEY_PREFIX = "weather:forecast:".freeze

  CachedForecast = Struct.new(:forecast, :fetched_at, keyword_init: true) do
    # Returns true once the cached data ages beyond the configured threshold.
    def stale?(threshold: WeatherCache::STALE_AFTER)
      return true if fetched_at.nil?
      fetched_at <= threshold.ago
    end
  end

  def initialize(redis: REDIS)
    @redis = redis
  end

  # Persists a serialized forecast snapshot alongside the fetch timestamp.
  def write(location, forecast, fetched_at: Time.current)
    redis.set(cache_key(location), payload(forecast, fetched_at).to_json, ex: TTL)
  end

  # Reads and rehydrates a cached forecast; returns nil on cache miss or parse issues.
  def read(location)
    raw = redis.get(cache_key(location))
    return unless raw

    data = JSON.parse(raw)
    CachedForecast.new(
      forecast: build_forecast(data.fetch("forecast")),
      fetched_at: parse_time(data["fetched_at"])
    )
  rescue JSON::ParserError, KeyError, ArgumentError
    nil
  end

  private

  attr_reader :redis

  # Parameterized keys keep Redis entries legible while stripping unsafe characters.
  def cache_key(location)
    "#{KEY_PREFIX}#{location.to_s.parameterize}"
  end

  def payload(forecast, fetched_at)
    {
      "forecast" => {
        "location" => forecast.location,
        "condition" => forecast.condition,
        "temperature_c" => forecast.temperature_c,
        "temperature_f" => forecast.temperature_f,
        "observed_at" => forecast.observed_at.iso8601
      },
      "fetched_at" => fetched_at.iso8601
    }
  end

  def build_forecast(attrs)
    Forecast.new(
      location: attrs.fetch("location"),
      condition: attrs.fetch("condition"),
      temperature_c: attrs.fetch("temperature_c"),
      temperature_f: attrs.fetch("temperature_f"),
      observed_at: parse_time(attrs.fetch("observed_at"))
    )
  end

  def parse_time(value)
    Time.zone.parse(value.to_s)
  end
end
