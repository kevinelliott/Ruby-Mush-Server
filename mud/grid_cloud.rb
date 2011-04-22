


module MUD
  class GridCloud
  
    # construct a new GridCloud
    def initialize
      @id = $WORLD.find_cloud_id
      $WORLD.register_cloud self
      @gridfields = Array.new # field ids
      @tspecs = nil # nil means default
      @weather = nil # nil means none, each GridCloud should have its own weather
      @weather_forecast = Hash.new
      @weather_forecast["starttime"] = 0
      @weather_forecast["endtime"] = 0
    end
    
    # register a field with this cloud
    # [param field:]      field for registering
    def register_field (field)
      if not self.field_exists? field
        @gridfields.push field.id
      end
    end
    
    # unregister a field with this cloud
    # [param field:]      field for unregistering
    def unregister_field (field)
      if self.field_exists? field
        @gridfields.delete field.id
      end
    end
	
	  # lists the properties of this gridcloud
	  # [returns:]			array of information
	  def info
	    output = Array.new
	    output.push "id: #{self.id}"
	    output.push "gridfields: #{@gridfields * ", "}"
	    output.push "timespecs: #{self.get_tspecs.id}"
	    output.push "weather: #{(@weather) ? @weather.id : "nil"}"
	    return output
	  end
    
    # check if a field is registered with this cloud
    # [param field:]      field for checking
    # [returns:]          true if field is registered
    def field_exists? (field)
      return @gridfields.include? field.id
    end
    
    def register_weather (weather)
      @weather = weather
    end
    
    def unregister_weather
      @weather = nil
    end
    
    # find a matching time specific for this cloud
    # [returns:]      local time specific or default time specific
    def get_tspecs
      return (not @tspecs) ? $WORLD.globaltime.default_spec : @tspecs
    end
    
    # calculate a new weather forecast if necessary and call a weather update
    # [returns:]      empty string or weather object to_s
    def compute_weather
      if not @weather
        return ""
      end
      
      # prevent new forecast until old has run out
      if @weather_forecast["endtime"] > self.get_tspecs.runtime_minutes
        @weather.update self.get_tspecs.runtime_minutes
        return @weather.to_s
      end
      
      # calculate forecast duration time
      @weather_forecast["starttime"] = self.get_tspecs.runtime_minutes
      @weather_forecast["endtime"] = @weather_forecast["starttime"] + 30 + rand(90)
      #@weather_forecast["endtime"] = @weather_forecast["starttime"] + 2
      
      rise_fall = SUPPORT::Math::rand_sgn
      # higher chance to sink temp while it is night
      is_day = (self.get_tspecs.compute_celestial_bodies(true, false)[0] =~ /day/) ? true : false
      if not is_day and SUPPORT::Math::rand_sgn == -1
        rise_fall = -1
      end
      self.calculate_temperature rise_fall
      self.calculate_humidity rise_fall # needs to be called after temperature
      self.calculate_weather_effects # needs to be called after temperature and humidity
      
      @weather.install_forecast @weather_forecast
      @weather.update self.get_tspecs.runtime_minutes
      return @weather.to_s
    end
    
    # calculate a new temperature forecast
    def calculate_temperature mul
      temp_mod = 0
      temp_mod = (@weather.current_temperature.abs / 6).floor if (mul < 0 and @weather.current_temperature < 0) or (mul > 0 and @weather.current_temperature > 0) # preventing increase when going up or decrease when down too far
      temp_change = rand(60) / (2 + temp_mod) # change will be capped more once it reaches higher numbers
      temp_current = @weather.temperature + (@weather.current_temperature - @weather.temperature) / 2 # adjust temperature to close in on the average
      temp = temp_current + mul * (temp_change) # apply the change
      @weather_forecast["temperature"] = SUPPORT::Math::round(temp, 2)
    end
    
    # calculate a new humidity forecast
    # [note: call this after temperature!]
    def calculate_humidity mul
      mul2 = (@weather_forecast["temperature"] < -15) ? -1 : 1 # run opposite if temperature reaches -15
      humid_current = @weather.humidity + (@weather.current_humidity - @weather.humidity) / 2 # adjust humidity to close in on the average
      humid = SUPPORT::Math::percent(humid_current + -1 * mul * mul2 * rand(60)) # change in opposite direction than temperature
      @weather_forecast["humidity"] = SUPPORT::Math::round(humid, 1)
    end
    
    # calculate a new weather effects forecast (clouds, wind, rain, thunderstorm)
    # [note: call this after temperature and humidity!]
    def calculate_weather_effects
      rains = 1 - ((@weather_forecast["temperature"] - 10).abs / 80) + (@weather_forecast["humidity"] / 100) # higher possibility to rain when humidity high and/or temperature closer to zero degrees
      @weather_forecast["rain"] = rains >= 1.15
      @weather_forecast["cloud"] = (rains - 1.0).abs * 100 # cloud level high when either rain strong or no rain but humidity and temperature balanced
      mul = SUPPORT::Math::rand_sgn
      mul = -1 if @weather.current_wind_level > 80
      mul = 1 if @weather.current_wind_level < 20
      wind = @weather.current_wind_level + (@weather.current_wind_level + @weather.wind_level) / 2 + mul * rand(40)
      @weather_forecast["wind"] = SUPPORT::Math::percent wind
      @weather_forecast["thunderstorm"] = @weather_forecast["cloud"] > 85 and humid > 80 # thunderstorm when cloud level high and humidity high
    end
    
    attr_accessor :gridfields, :tspecs, :weather, :id
  end
end
