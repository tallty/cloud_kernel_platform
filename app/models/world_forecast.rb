class WorldForecast
  attr_accessor :publish_time, :site_name, :city, :weather, :ltemp, :htemp

  def process
    puts "#{DateTime.now}: do World Forcast process ..."

    WorldForecastProcess.new.process
  end

  def as_json options=nil
    {
      publish_time: publish_time,
      city: city,
      weather: weather,
      ltemp: ltemp,
      htemp: htemp
    }
  end

  class WorldForecastProcess < BaseForecast
    def initialize()
      super
      @redis_key = "world_forecast_v2"
      @redis_last_report_time_key = "world_forecast_last_report_time_v2"

    end

    def get_report_time_string filename
      p filename
      @connection.mtime(filename).strftime("%Y-%m-%d %H:%M:%S")
    end

    def ftpfile_format day
      "City2.txt"
    end

    def parse local_file
      file = File.open(local_file, 'r')
      # date_time = (Time.now.to_date).strftime("%Y-%m-%d")
      date_time = (Time.now.to_date + 1.day).strftime("%Y-%m-%d")
      file.each do |line|
        line = line.encode! 'utf-8', 'gb2312', {:invalid => :replace}
        if line =~ /\d{5,6}/
          contents = line.split(" ")
          item = WorldForecast.new
          item.publish_time = date_time
          item.city = contents[1]
          item.weather = contents[2] == contents[3] ? contents[2].chomp('天') : contents[2].chomp('天') + '转' + contents[3].chomp('天')
          item.ltemp = contents[4]
          item.htemp = contents[5]
          $redis.hset @redis_key, "#{item.city}", item.to_json
        end
      end
      file.close
    end

  end
end
