


module MUD
  class TimeSpecifics
    
    # construct a new time specific
    # [param yr:]     one year has this many months
    # [param mon:]    one month has this many days
    # [param day:]    one day has this many hours
    # [param se:]     array of seasons per year
    # [param byr:]    baseyear the specs should begin to count from
    def initialize (yr, mon, day, se, byr)
      @id = $WORLD.globaltime.find_spec_id
      $WORLD.globaltime.register_tspec self
      @year_len = yr
      @month_len = mon
      @day_len = day
      @seasons = se # is array
      @baseyear = byr
      @firstboot = TimeSpecifics::calc_firstboot Time.now.getutc.strftime("%m/%d/%Y")
      @celestial_bodies = Array.new
    end
    
    def register_celestial (cbody)
      @celestial_bodies.push cbody.id
    end
    
    def unregister_celestial (cbody)
      @celestial_bodies.delete cbody.id
    end
    
    # calculate how long the world has run in minutes
    # [returns:]      amount of minutes
    def runtime_minutes
      runtime_seconds = Time.now.getutc - @firstboot
      return (runtime_seconds / 60.0).floor
    end
    
    # calculate how long the world has run in hours
    # [returns:]      amount of hours
    def runtime_hours
      minutes = self.runtime_minutes
      return (minutes / 60.0).floor
    end
    
    # calculate how long the world has run in days
    # [returns:]      amount of days
    def runtime_days
      hours = self.runtime_hours
      return (hours / @day_len).floor
    end
    
    # calculate how long the world has run in months
    # [returns:]      amount of months
    def runtime_months
      days = self.runtime_days
      return (days / @month_len).floor
    end
    
    # calculate how long the world has run in years
    # [returns:]      amount of years
    def runtime_years
      months = self.runtime_months
      return (months / @year_len).floor + @baseyear
    end
    
    # calculate how many months have passed this year
    # [returns:]      amount of months
    def months_this_year
      years = self.runtime_years - @baseyear
      months = self.runtime_months
      return months - years * @year_len + 1
    end
    
    # calculate how many days have passed this month
    # [returns:]      amount of days
    def days_this_month
      months = self.runtime_months
      days = self.runtime_days
      return days - months * @month_len + 1
    end
    
    # calculate how many hours have passed this day
    # [returns:]      amount of hours
    def hours_this_day
      days = self.runtime_days
      hours = self.runtime_hours
      return hours - days * @day_len
    end
    
    # calculate how many minutes have passed this hour
    # [returns:]      amount of minutes
    def minutes_this_hour
      hours = self.runtime_hours
      minutes = self.runtime_minutes
      return minutes - hours * 60
    end
    
    # calculate a status for any celestial body attached to this time specific
    # [param daylight:]     should the day/night status be added to the output? default: true
    # [param bodies:]       should the status for each visible body be added to the output? default: true
    # [returns:]            array of status including day/night
    def compute_celestial_bodies (daylight=true, bodies=true)
      result = Hash.new
      output = Array.new
      
      # determine visible bodies by checking their position
      for i in 0...@celestial_bodies.length
        body = $WORLD.object_map[@celestial_bodies[i]]
        circle_minutes = body.circle_time * @day_len * 60
        moved_today = self.runtime_minutes % circle_minutes
        moved_percent = (100 * moved_today / (@day_len * 60)).floor
        past_zero = nil
        past_zero = body.visible_time + body.become_visible - 99 if body.visible_time + body.become_visible > 99
        if (past_zero and moved_percent <= past_zero) or (moved_percent >= body.become_visible and moved_percent <= body.visible_time + body.become_visible)
          moved_part = (past_zero and moved_percent <= past_zero) ? 99 - body.become_visible + moved_percent : moved_percent - body.become_visible
          result[body] = (100 * moved_part / body.visible_time).floor
        end
      end
      
      # create output for visible bodies
      is_day = false
      for i in 0...result.keys.length
        body = result.keys[i]
        value = result[body]
        standing = case value
          when 0..10 then "dawning"
          when 11..40 then "rising"
          when 41..60 then "in zenith"
          when 61..90 then "setting"
          else "at dusk"
        end
        direction = case value
          when 0..40 then " in the " + MUD::World::full_name(MUD::World::opposite_direction(body.direction))
          when 40..50 then ""
          else " in the " + MUD::World::full_name(body.direction)
        end
        sun = ""
        if body.is_sun
          is_day = true
          sun = " (a sun)"
        else
          phase = body.phases[self.runtime_days % body.phases_time]
          sun = " (phase: #{phase})"
        end
        output.push "#{body.name}#{sun} is #{standing}#{direction}." if bodies
      end
      
      # determine day/night and create output
      if is_day
        output.push "It is currently day." if daylight
      else
        output.push "It is currently night." if daylight
      end
      return output
    end
    
    # calculate a status for time, seasons and date
    # [returns:]          array of status
    def compute_time
      output = Array.new
      output.push "The time is #{self.hours_this_day}:#{self.minutes_this_hour}."
      output.push "This is day #{self.days_this_month} in the month #{self.months_this_year} of the year #{self.runtime_years}."
      
      minutes_year = @year_len * @month_len * @day_len * 60
      moved_so_far = self.runtime_minutes % minutes_year
      moved_percent = (100 * moved_so_far / (@year_len * @month_len * @day_len * 60)).floor
      season_percent = (100 * 1 / @seasons.length).floor
      season_num = (moved_percent / season_percent).floor
      current_season = @seasons[season_num]
      output.push "The current season is #{current_season}. Number #{season_num + 1} of total #{@seasons.length}."
      
      return output
    end
    
    # calculate general information on the celestial bodies attached to this time specific
    # [returns:]          array of status
    def list_celestial_bodies
      output = Array.new
      for i in 0...@celestial_bodies.length
        body = $WORLD.object_map[@celestial_bodies[i]]
        output.push "#{body.name} is moving from #{MUD::World::full_name(MUD::World::opposite_direction(body.direction))} to #{MUD::World::full_name(body.direction)} throughout #{body.circle_time} day(s) while cycling #{body.phases.length} phases (#{body.phases * ", "}) each taking #{body.phases_time} day(s)." if not body.is_sun
        output.push "#{body.name} (a sun) is moving from #{MUD::World::full_name(MUD::World::opposite_direction(body.direction))} to #{MUD::World::full_name(body.direction)} throughout #{body.circle_time} day(s)." if body.is_sun
      end
      return output
    end
    
    # list the properties of this time specific
    # [returns:]          array of information
    def info
      output = Array.new
      output.push "id: #{self.id}"
      output.push "year length: #{self.year_len}"
      output.push "month length: #{self.month_len}"
      output.push "day length: #{self.day_len}"
      output.push "seasons: #{self.seasons * ", "}"
      output.push "baseyear: #{self.baseyear}"
      output.push "firstboot: #{self.firstboot.to_s}"
      output.push "celestial bodies (ids) attached: #{self.celestial_bodies * ", "}"
      return output
    end
    
    # translates any time string to a time object in UTC
    # [param str:]      time string can be any valid representation, the system can process
    # [returns:]        utc time object
    def TimeSpecifics::calc_firstboot (str)
      t = Time.parse str
      utc = Time.utc t.year, t.month, t.day
      return utc
    end
    
    attr_accessor :celestial_bodies, :id, :firstboot, :year_len, :month_len, :day_len, :seasons, :baseyear
  end
end
