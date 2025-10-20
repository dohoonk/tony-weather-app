class WeatherController < ApplicationController
  before_action :require_login
  
  def show
    address_query = AddressQuery.new(params[:address])
    location = address_query.value || default_location

    @address_query = address_query
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
