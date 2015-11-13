class GridLive
  
  def self.process
    Grid500Process.new.process
  end

  class Grid500Process < BaseForecast
    def initialize
      super

      @redis_last_report_time_key = "grid_500_last_report_time"
      # $redis.del @redis_last_report_time_key
      @grid_info_redis_key = "grid_500_info"
      @redis_key = "grid_500m"

      @remote_dir = @remote_dir.encode('gbk')
    end

    def get_report_time_string file_name
      report_time_string = file_name.split(/\_|\./)[-2]
    end

    def ftpfile_format day
      "*10m_#{to_date_string(day)}*.txt"
    end

    def parse file_name
      file_info = file_name.split(/\/|\_|\./)
      file_type = file_info[-3].gsub("10m", "")
      file_date_time = file_info[-2]
      if file_type.eql?("wind")
        parse_station_file(file_name, file_type, file_date_time)
      else
        parse_grid_file(file_name, file_type, file_date_time)
      end
    end

    def parse_station_file(file_name, file_type, time)
      line_count = 0
      File.foreach(file_name, encoding: @file_encoding) do |line| 
        line = line.encode "utf-8"
        line_contents = line.chomp.split(',')
        if station_line_type(line_contents) == :file_data
          # p line_contents
          obj = {
            jd: line_contents[1].to_f,
            wd: line_contents[2].to_f,
            wind_direction: line_contents[3].to_f,
            wind_speed: line_contents[4].to_f
          }
          $redis.hset "#{@redis_key}_#{time}", "#{file_type}_#{line_count}", obj.to_json
          line_count += 1
        end
      end
      $redis.hset @grid_info_redis_key, "wind_count", line_count
    end

    def parse_grid_file(file_name, file_type, time)
      $redis.hset @grid_info_redis_key, "last_time", time
      line_count = 0
      File.foreach(file_name, encoding: @file_encoding) do |line|
        line = line.encode 'utf-8'
        line_contents = line.split(' ')
        type = grid_line_type line_contents
        if type == :location_info
          $redis.hset @grid_info_redis_key, "origin_lon", line_contents[0]
          $redis.hset @grid_info_redis_key, "term_lon", line_contents[1]
          $redis.hset @grid_info_redis_key, "origin_lat", line_contents[2]
          $redis.hset @grid_info_redis_key, "term_lat", line_contents[3]
          $redis.hset @grid_info_redis_key, "lon_interval", line_contents[4]
          $redis.hset @grid_info_redis_key, "lat_interval", line_contents[5]
        elsif type == :data_info
          $redis.hset @grid_info_redis_key, "lon_count", line_contents[0]
          $redis.hset @grid_info_redis_key, "lat_count", line_contents[1]
        elsif type == :data
          $redis.hset("#{@redis_key}_#{time}", "#{file_type}_#{line_count}", line.chomp)
          line_count = line_count + 1
        end
      end
    end

    private

    def station_line_type line_contents
      line_type = :file_data
      if line_contents.size == 5
        line_type = :file_data
      else
        line_type = :unuse
      end
      line_type
    end

    def grid_line_type line_contents
      line_type = :time
      if line_contents.size == 1 or line_contents.size == 5
        line_type = :time
      elsif line_contents.size == 6
        line_type = :location_info
      elsif line_contents.size == 2
        line_type = :data_info
      else
        line_type = :data
      end
    end

    def after_process
      last_redis_key =$redis.hget @grid_info_redis_key, "last_time"
      keys = $redis.keys "#{@redis_key}*"
      keys.each do |item|
        $redis.del item unless "#{@redis_key}_#{last_redis_key}".eql?(item)
      end
      
      @process_result_info["end_time"] = DateTime.now.to_f
      push_task_log @process_result_info.to_json
    end
  end
end
