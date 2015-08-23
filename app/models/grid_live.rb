class GridLive

  def process
    Grid500Process.new.process
  end

  class Grid500Process < BaseForecast
    def initialize
      super

      @redis_last_report_time_key = "grid_500_last_report_time"
      
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
      file_type = file_info[-3].delete("10m")
      file_date_time = file_info[-2]
      line_count = 0
      File.foreach(file_name, encoding: @file_encoding) do |line|
        line = line.encode 'utf-8'
        line_contents = line.split(' ')
        type = line_type line_contents
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
          $redis.hset("#{@redis_key}_#{file_date_time}", "#{file_type}_#{line_count}", line)
          line_count = line_count + 1
        end
      end
    end

    private
    def line_type line_contents
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
      last_redis_key = $redis.get @redis_last_report_time_key

      keys = $redis.keys "#{@redis_key}*"
      keys.each do |item|
        $redis.del item unless "#{@redis_key}_#{last_redis_key}".eql?(item)
      end
    end
  end
end
