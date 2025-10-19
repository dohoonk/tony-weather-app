class WeatherController < ApplicationController
  def show
    location = params[:location].presence || default_location
    @forecast = weather_service.fetch(location:)
  rescue WeatherService::Error
    flash.now[:alert] = "Unable to fetch weather right now."
    @forecast = Forecast.example
  end
  
  private

  def weather_service
    @weather_service ||= WeatherService.new
  end

  def default_location
    "San Francisco, CA"
  end
end
