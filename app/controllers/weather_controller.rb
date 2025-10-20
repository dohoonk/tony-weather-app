class WeatherController < ApplicationController
  before_action :require_login
  
  def show
    # Resolve location, serve cached forecast when possible.
    address_query = AddressQuery.new(params[:address])
    location = address_query.value || default_location

    cached = weather_cache.read(location)

    if cached
      apply_cached_forecast(cached)
      enqueue_refresh(location) if @stale
    else
      apply_live_forecast(
        weather_service.fetch(location: location),
        location
      )
    end

    @address_query = address_query
  rescue WeatherService::Error
    # Gracefully degrade when the live fetch fails, then queue a refresh.
    flash.now[:alert] = "Unable to fetch weather right now."
    cached ? apply_cached_forecast(cached, stale: true)
         : apply_fallback_forecast

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
  def apply_cached_forecast(cached, stale: cached.stale?)
    @forecast = cached.forecast
    @stale = stale
    @last_fetched_at = cached.fetched_at
  end
  
  # Updates state with fresh data and persists to cache.
  def apply_live_forecast(forecast, location)
    @forecast = forecast
    @stale = false
    @last_fetched_at = Time.current
    weather_cache.write(location, forecast, fetched_at: @last_fetched_at)
  end
  
  # Default fallback when nothing usable exists.
  def apply_fallback_forecast
    @forecast = Forecast.example
    @stale = true
    @last_fetched_at = Time.current
  end

  def weather_cache
    @weather_cache ||= WeatherCache.new
  end

  def enqueue_refresh(location)
    WeatherFetchJob.perform_async(location)
  end
end
