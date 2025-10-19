class WeatherController < ApplicationController
  def show
    @forecast = Forecast.example
  end
end
