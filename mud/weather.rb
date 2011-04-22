


module MUD
  class Weather
  
    # constructs a new weather
    # [param hum:]    average relative humidity across one year in percent
    # [param temp:]   average temperature across one year in degrees celsius
    # [param wl:]     average wind level across a year in percent, with 100% being enough to tear down anything close to a 10000yr old mountain range
    def initialize (hum, temp, wl)
      @id = $WORLD.find_id
      $WORLD.register_object self
      @humidity = hum
      @temperature = temp
      @wind_level = wl
      
      @thunderstorm = nil # nil or number
      @raining = nil # nil or number
      @current_temperature = temp
      @current_humidity = hum
      @current_wind_level = wl
      @current_cloud_level = 10.0
      @forecast_data = Hash.new
    end
	
	# lists the properties of this gridcloud
	# [returns:]			array of information
	def info
	  output = Array.new
	  output.push "id: #{self.id}"
	  output.push "humidity: #{self.humidity}"
	  output.push "temperature: #{self.temperature}"
	  output.push "wind level: #{self.wind_level}"
	  return output
	end
    
    # register a new forecast with the object
    # [param forecast:]     hash consisting of these keys: starttime, time_lastupdate, endtime, runtime, temperature, humidity, rain, cloud, wind, thunderstorm
    def install_forecast (forecast)
      @forecast_data["starttime"] = forecast["starttime"]
      @forecast_data["time_lastupdate"] = forecast["starttime"]
      @forecast_data["endtime"] = forecast["endtime"]
      @forecast_data["runtime"] = forecast["endtime"] - forecast["starttime"]
      @forecast_data["temperature"] = SUPPORT::Math::round(forecast["temperature"], 2)
      @forecast_data["humidity"] = SUPPORT::Math::round(forecast["humidity"], 2)
      @forecast_data["rain"] = forecast["rain"]
      @forecast_data["cloud"] = SUPPORT::Math::round(forecast["cloud"], 2)
      @forecast_data["wind"] = SUPPORT::Math::round(forecast["wind"], 2)
      @forecast_data["thunderstorm"] = forecast["thunderstorm"]
    end
    
    # update the weather every minute
    # [param tspecs_runtime_minutes:]     current runtime in minutes of time specific
    def update (tspecs_runtime_minutes)
      if tspecs_runtime_minutes <= @forecast_data["time_lastupdate"]
        return
      end
      @forecast_data["time_lastupdate"] += 1
      self.adjust_temperature
      self.adjust_humidity
      self.adjust_cloud_level
      self.adjust_wind_level
      self.adjust_weather_effects
    end
    
    # normal to_s method
    def to_s
      output = Array.new
      output.push "The current temperature is %.2f degrees Celsius." % @current_temperature
      output.push "The relative humidity is " + "%.2f" % @current_humidity + "%."
      output.push "#{Weather::wind_level_names(@current_wind_level).capitalize} is around you."
      output.push "The sky is #{Weather::cloud_level_names(@current_cloud_level)}."
      output.push "#{Weather::rain_level_names(@raining).capitalize} is coming from above." if @raining and @current_temperature >= 0 and not Weather::cloud_level_names(@current_cloud_level) == "clear"
      output.push "#{Weather::snow_level_names(@raining).capitalize} is coming from above." if @snowing and @current_temperature < 0 and not Weather::cloud_level_names(@current_cloud_level) == "clear"
      output.push "Thunder and lightning strike the skies from time to time." if @thunderstorm
      return output
    end
    
    # update the weather effects like rain/snow and thunderstorms
    def adjust_weather_effects
      # decrease rain if it's not forecasted but active
      if not @forecast_data["rain"] and @raining
        @raining -= $RAIN_SNOW_ADJUST
        @raining = nil if @raining <= 0
      # increase rain until it reaches cloud level, enable it if inactive
      elsif @forecast_data["rain"] and not @raining == @current_cloud_level
        @raining = 0 if not @raining
        rain = (@raining) ? @raining : 0
        @raining += SUPPORT::Math::sgn(@current_cloud_level - rain) * $RAIN_SNOW_ADJUST
      end
      
      # enable thunderstorm if forecasted and cloudlevel is overcast
      @thunderstorm = @forecast_data["thunderstorm"] and Weather::cloud_level_names(@current_cloud_level) == "overcast"
    end
    
    # update the cloud coverage unless it's equal to forecast
    def adjust_cloud_level
      @current_cloud_level += SUPPORT::Math::sgn(@forecast_data["cloud"] - @current_cloud_level) * $CLOUD_LEVEL_ADJUST if not @current_cloud_level == @forecast_data["cloud"]
    end
    
    # update the wind speed unless it's equal to forecast
    def adjust_wind_level
      @current_wind_level += SUPPORT::Math::sgn(@forecast_data["wind"] - @current_wind_level) * $WIND_LEVEL_ADJUST if not @current_wind_level == @forecast_data["wind"]
    end
    
    # update the humidity unless it's equal to forecast
    def adjust_humidity
      @current_humidity += SUPPORT::Math::sgn(@forecast_data["humidity"] - @current_humidity) * $HUMIDITY_ADJUST if not @current_humidity == @forecast_data["humidity"]
    end
    
    # update the temperature unless it's equal to forecast
    def adjust_temperature
      @current_temperature += SUPPORT::Math::sgn(@forecast_data["temperature"] - @current_temperature) * $TEMPERATURE_ADJUST if not @current_temperature == @forecast_data["temperature"]
    end
    
    # translate the wind speed to a string
    # [param num:]    wind speed in percent
    # [returns:]      string
    def Weather::wind_level_names (num)
      arr = ["a calm air", "a light breeze", "a gentle breeze", "a fresh wind", "a strong wind", "a gale", "a whole gale", "a hurricane"]
      index = ((arr.length) * num / 100).floor
      return (num) ? arr[index] : ""
    end
    
    # translate the cloud coverage to a string
    # [param num:]    cloud coverage in percent
    # [returns:]      string
    def Weather::cloud_level_names (num)
      arr = ["clear", "partly cloudy", "mostly cloudy", "overcast"]
      index = case num
        when 0..15 then 0
        when 15..60 then 1
        when 60..85 then 2
        else 3
      end
      return (num) ? arr[index] : ""
    end
    
    # translate the amount of rain to a string
    # [param num:]    amount of rain in percent
    # [returns:]      string
    def Weather::rain_level_names (num)
      if not num
        return "no rain"
      end
      arr = ["light rain", "moderate rain", "heavy rain", "violent rain"]
      index = case num
        when 0..10 then 0
        when 10..30 then 1
        when 30..70 then 2
        else 3
      end
      return arr[index]
    end
    
    # translate the amount of snow to a string
    # [param num:]    amount of snow in percent
    # [returns:]      string
    def Weather::snow_level_names (num)
      if not num
        return "no snow"
      end
      arr = ["light snow", "moderate snow", "heavy snow"]
      index = case num
        when 0..30 then 0
        when 30..60 then 1
        else 2
      end
      return arr[index]
    end
    
    attr_accessor :id, :current_humidity, :current_temperature, :humidity, :temperature, :current_cloud_level, :wind_level, :current_wind_level
  end
end
