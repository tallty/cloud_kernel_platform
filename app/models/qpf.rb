class QPF

  def process
    QpfProcess.new.process
  end


  class QpfProcess < BaseLocalFile
    def initialize
      super

      @redis_last_report_time_key = "grid_qpf_last_report_time"
    end

    def file_format
      ".*.(000|006|012|018|024|030|036|042|048|054|060|066|072|078|084|090)"
    end

    def get_report_time_string filename
      file_time = "20#{filename.split(/\.|\//)[-2]}"
      Time.parse(file_time)
    end

    def parse file
      file_tag = file.split(/\.|\//)
      $redis.hset "qpf_info", "origin_time", file_tag[-2]
      file_index = file_tag[-1].to_i
      lon_count = 0
      lat_count = 0
      file_lon_count = 0
      arr = []
      File.foreach(file) do |line|
        contents = line.split(' ')
        type = line_type contents
        if type == :data_info
          $redis.hset "qpf_info", "origin_lon", contents[8]
          $redis.hset "qpf_info", "term_lon", contents[9]
          $redis.hset "qpf_info", "origin_lat", contents[10]
          $redis.hset "qpf_info", "term_lat", contents[11]
          $redis.hset "qpf_info", "lon_count", contents[12]
          file_lon_count = contents[12].to_i
          $redis.hset "qpf_info", "lat_count", contents[13]
        elsif type == :data
          arr << contents
          lon_count += 1
          if lon_count >= 44
            lon_count = 0
            lat_count += 1
            $redis.hset("grid_qpf", "#{lat_count}_#{file_index}", arr.flatten.to_json)
            arr.clear
          end
        end
      end
    end

    private
    def line_type line_contents
      line_type = :file_info
      if line_contents.size == 3 and line_contents[0].eql?('diamond')
        line_type = :file_info
      elsif line_contents.size == 19
        line_type = :data_info
      else
        line_type = :data
      end
      line_type
    end
  end
end