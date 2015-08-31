class WorldForecast
  attr_accessor :publish_time, :site_name, :city, :weather, :ltemp, :htemp

  def self.process
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
      @redis_last_report_time_key = "world_forecast_last_report_time"

      connect! unless @connection
    end

    def process
      get_report_time_string @file
      last_report_time = $redis.get @redis_last_report_time_key
      if(nil == last_report_time || last_report_time != @report_time_string)
        parse @local_file
        $redis.set @redis_last_report_time_key, "#{@report_time_string}"
        puts "世界城市预报更新结束."
      end
    end 

    def get_report_time_string filename
      FileUtils.makedirs(@local_dir) unless File.exist?(@local_dir)
      today = Time.new
      file_local_dir = File.join @local_dir, today.strftime('%Y-%m-%d')
      FileUtils.makedirs(file_local_dir) unless File.exist?(file_local_dir)
      @local_file = File.join file_local_dir, filename
      @connection.getbinaryfile(filename, @local_file)

      file = File.open(@local_file, :encoding => 'gb2312')
      line = file.readline
      line = line.encode('utf-8').chomp
      
      md = /上海中心气象台国际城市天气预报：(\d{1,2})月(\d{1,2})日(..)/.match(line)
      file.close
      @report_time_string = "#{today.strftime('%Y')}-#{$1}-#{$2}"
    end

    def ftpfile_format day
      @file
    end

    def parse local_file
      puts "#{@report_time_string}"
      file = File.open(local_file, 'r')
      file.each do |line|
        line = line.encode! 'utf-8', 'gb2312', {:invalid => :replace}
        if line =~ /\d{5,6}/
          contents = line.split(" ")
          item = WorldForecast.new
          item.publishtime = @report_time_string
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
