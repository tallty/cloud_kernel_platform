class QPF

  def process
    p "#{Time.now.strftime('%Y-%m-%d %H:%M')}: process qpf task..."
    QpfProcess.new.process
    QpfJsonProcess.new.process
  end

  class QpfJsonProcess < BaseLocalFile
    def initialize
      super
      @redis_last_report_time_key = "qpf_json_last_report_time"
    end

    def file_format
      ".*.(000|006|012|018|024|030|036|042|048|054|060|066|072|078|084|090)"
    end

    def get_report_time_string file_name
      "20#{file_name.split(/\.|\//)[-2]}"
    end

    def parse file
      # p "process file: #{file}"
      line_count = 0
      origin_lon = 0
      origin_lat = 0
      base_origin_lon = 0
      base_origin_lat = 0
      datas = []
      File.foreach(file) do |line|
        line_count += 1
        contents = line.split(' ')
        if line_count < 3
          if line_count == 2
            # p "contents: #{contents}"
            origin_lon = contents[8].to_f
            origin_lat = contents[10].to_f
            base_origin_lon = origin_lon
            base_origin_lat = origin_lat
          end
        else
          contents.each do |content|
            if (origin_lon < 122 and origin_lon > 121) and (origin_lat < 32 and origin_lat > 30)
              datas << {
                jd: origin_lon.round(2),
                wd: origin_lat.round(2),
                data: content.to_f.round(1)
              }
            end
            origin_lon += 0.01
          end
          if (line_count - 2) % 44 == 0
            origin_lat += 0.01
            origin_lon = base_origin_lon
          end
        end
      end
      file_index = file.scan(/[^\.]+$/)[0]
      # p "datas size is: #{datas.size}"
      $redis_qpf.hset "qpf_all_json", file_index, datas.to_json
      datas.clear
    end
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
      p "process qpf file: #{file}"
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
          $redis.multi do
            $redis.hset "qpf_info", "origin_lon", contents[7]
            $redis.hset "qpf_info", "term_lon", contents[8]
            $redis.hset "qpf_info", "origin_lat", contents[9]
            $redis.hset "qpf_info", "term_lat", contents[10]
            $redis.hset "qpf_info", "lon_count", contents[11]
            $redis.hset "qpf_info", "lat_count", contents[12]
          end
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
      if @process_file_infos.present?
        @process_result_info["end_time"] = DateTime.now.to_f
        push_task_log @process_result_info.to_json
      end
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
