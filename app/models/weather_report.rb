class WeatherReport
  attr_reader :location, :current, :daily

  def initialize(location:, current:, daily: [])
    @location = location
    @current = current
    @daily = daily
  end
end
