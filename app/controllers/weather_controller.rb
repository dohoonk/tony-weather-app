class WeatherController < ApplicationController
  before_action :require_login
  
  def show
    # Resolve location, serve cached forecast when possible.
    address_query = AddressQuery.new(params[:address])
    location = address_query.value || default_location

    cached = weather_cache.read(location)

    if cached
      apply_cached_report(cached)
      enqueue_refresh(location) if @stale
    else
      apply_live_report(
        weather_service.fetch(location: location),
        location
      )
    end

    @address_query = address_query
  rescue WeatherService::Error
    # Gracefully degrade when the live fetch fails, then queue a refresh.
    flash.now[:alert] = "Unable to fetch weather right now."
    cached ? apply_cached_report(cached, stale: true)
         : apply_fallback_report

    enqueue_refresh(location)
  end

  private

  def weather_service
    @weather_service ||= WeatherService.new
  end

  def default_location
    "San Francisco, CA"
  end

  # Copies cached attributes into controller state
  def apply_cached_report(cached, stale: cached.stale?)
    @report = cached.report
    @stale = stale
    @last_fetched_at = cached.fetched_at
    @from_cache = true
  end
  
  # Updates state with fresh data and persists to cache.
  def apply_live_report(report, location)
    @report = report
    @stale = false
    @last_fetched_at = Time.current
    @from_cache = false
    weather_cache.write(location, report, fetched_at: @last_fetched_at)
  end
  
  # Default fallback when nothing usable exists.
  def apply_fallback_report
    fallback_forecast = Forecast.example
    @report = WeatherReport.new(
      location: fallback_forecast.location,
      current: fallback_forecast,
      daily: []
    )
    @stale = true
    @last_fetched_at = Time.current
    @from_cache = false
  end

  def weather_cache
    @weather_cache ||= WeatherCache.new
  end

  def enqueue_refresh(location)
    WeatherFetchJob.perform_async(location)
  end
end
