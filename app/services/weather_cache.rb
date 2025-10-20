class WeatherCache
  TTL = 30.minutes
  STALE_AFTER = 5.minutes
  KEY_PREFIX = "weather:forecast:".freeze

  CachedReport = Struct.new(:report, :fetched_at, keyword_init: true) do
    def stale?(threshold: WeatherCache::STALE_AFTER)
      return true if fetched_at.nil?

      fetched_at <= threshold.ago
    end
  end

  def initialize(redis: REDIS)
    @redis = redis
  end

  def write(location, report, fetched_at: Time.current)
    redis.set(cache_key(location), payload(report, fetched_at).to_json, ex: TTL)
  end

  def read(location)
    raw = redis.get(cache_key(location))
    return unless raw

    data = JSON.parse(raw)
    CachedReport.new(
      report: build_report(data.fetch("report")),
      fetched_at: parse_time(data["fetched_at"])
    )
  rescue JSON::ParserError, KeyError, ArgumentError
    nil
  end

  private

  attr_reader :redis

  def cache_key(location)
    "#{KEY_PREFIX}#{location.to_s.parameterize}"
  end

  def payload(report, fetched_at)
    {
      "report" => {
        "location" => report.location,
        "current" => serialize_forecast(report.current),
        "daily" => report.daily.map { |d| serialize_daily(d) }
      },
      "fetched_at" => fetched_at.iso8601
    }
  end

  def serialize_forecast(forecast)
    {
      "location" => forecast.location,
      "condition" => forecast.condition,
      "temperature_c" => forecast.temperature_c,
      "temperature_f" => forecast.temperature_f,
      "observed_at" => forecast.observed_at.iso8601,
      "high_temperature_c" => forecast.high_temperature_c,
      "high_temperature_f" => forecast.high_temperature_f,
      "low_temperature_c" => forecast.low_temperature_c,
      "low_temperature_f" => forecast.low_temperature_f,
      "icon_url" => forecast.icon_url
    }
  end

  def serialize_daily(forecast)
    {
      "date" => forecast.date,
      "condition" => forecast.condition,
      "high_temperature_c" => forecast.high_temperature_c,
      "high_temperature_f" => forecast.high_temperature_f,
      "low_temperature_c" => forecast.low_temperature_c,
      "low_temperature_f" => forecast.low_temperature_f,
      "icon_url" => forecast.icon_url
    }
  end

  def build_report(attrs)
    WeatherReport.new(
      location: attrs.fetch("location"),
      current: build_forecast(attrs.fetch("current")),
      daily: attrs.fetch("daily", []).map { |day| build_daily(day) }
    )
  end

  def build_forecast(attrs)
    Forecast.new(
      location: attrs.fetch("location"),
      condition: attrs.fetch("condition"),
      temperature_c: attrs.fetch("temperature_c"),
      temperature_f: attrs.fetch("temperature_f"),
      observed_at: parse_time(attrs.fetch("observed_at")),
      high_temperature_c: attrs["high_temperature_c"],
      high_temperature_f: attrs["high_temperature_f"],
      low_temperature_c: attrs["low_temperature_c"],
      low_temperature_f: attrs["low_temperature_f"],
      icon_url: attrs["icon_url"]
    )
  end

  def build_daily(attrs)
    DailyForecast.new(
      date: attrs.fetch("date"),
      condition: attrs.fetch("condition"),
      high_temperature_c: attrs.fetch("high_temperature_c"),
      high_temperature_f: attrs.fetch("high_temperature_f"),
      low_temperature_c: attrs.fetch("low_temperature_c"),
      low_temperature_f: attrs.fetch("low_temperature_f"),
      icon_url: attrs["icon_url"]
    )
  end

  def parse_time(value)
    Time.zone.parse(value.to_s)
  end
end
