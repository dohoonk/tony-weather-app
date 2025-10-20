class WeatherFetchJob
  include Sidekiq::Job

  sidekiq_options queue: :weather, retry: 3

  def perform(location)
    forecast = weather_service.fetch(location: location)
    weather_cache.write(location, forecast)
  rescue WeatherService::Error => error
    Rails.logger.warn("WeatherFetchJob failed for #{location}: #{error.message}")
  end

  private

  def weather_service
    @weather_service ||= WeatherService.new
  end

  def weather_cache
    @weather_cache ||= WeatherCache.new
  end
end
