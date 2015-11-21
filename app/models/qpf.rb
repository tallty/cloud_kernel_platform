class QPF

  def process
    p "#{Time.now.strftime('%Y-%m-%d %H:%M')}: process qpf task..."
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

    def get_report_time_string file_name
      "20#{file_name.split(/\.|\//)[-2]}"
    end

    def parse file
      file_tag = file.split(/\.|\//)
      $redis.hset "qpf_info", "origin_time", Time.parse("20#{file_tag[-2]}") + 8.hour
      file_index = file_tag[-1].to_i
      lon_count = 0
      lat_count = 0
      arr = []
      FileUtils.makedirs(@dest_folder) unless File.exist?(@dest_folder)
      dest_file_path = File.join(@dest_folder, File.basename(file))
      dest_file = File.new(dest_file_path, "w")

      File.foreach(file) do |line|
        contents = line.split(' ')
        type = line_type contents
        if type == :data_info
          exchange_content = "#{Time.now.strftime('%y')} #{Time.now.strftime('%m')} "
          (1..contents.size).each {|i| exchange_content << "#{contents[i]} " }
          exchange_content << "\r\n"
          dest_file.write(exchange_content)
          $redis.hset "qpf_info", "origin_lon", contents[7]
          $redis.hset "qpf_info", "term_lon", contents[8]
          $redis.hset "qpf_info", "origin_lat", contents[9]
          $redis.hset "qpf_info", "term_lat", contents[10]
          $redis.hset "qpf_info", "lon_count", contents[11]
          $redis.hset "qpf_info", "lat_count", contents[12]
        elsif type == :data
          dest_file.write(line)
          arr << contents
          lon_count += 1
          if lon_count >= 44
            lon_count = 0
            lat_count += 1
            $redis.hset("grid_qpf", "#{lat_count}_#{file_index}", arr.flatten.to_json)
            arr.clear
          end
        else
          dest_file.write(line)
        end
      end
      dest_file.close
    end

    def after_process
      @process_result_info["end_time"] = DateTime.now.to_f
      push_task_log @process_result_info.to_json
    end

    private
    def line_type line_contents
      line_type = :file_info
      if line_contents.size == 3 and line_contents[0].eql?('diamond')
        line_type = :file_info
      elsif line_contents.size == 18
        line_type = :data_info
      else
        line_type = :data
      end
      line_type
    end
  end
end
