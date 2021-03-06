class ExchangeFile

  def self.process
    AirPressureProcess.new.process
    SurfacePressureProcess.new.process
  end

  class AirPressureProcess < BaseLocalFile
    def initialize
      super

      @redis_last_report_time_key = "exchange_air_pressure_last_report_time"
    end

    def file_format
      ".*"
    end

    def get_report_time_string file_name
      File.ctime(file_name).strftime("%Y%m%d%H%M%S")
    end

    def parse file_name
      FileUtils.makedirs(@dest_folder) unless File.exist?(@dest_folder)
      dest_file_path = File.join(@dest_folder, File.basename(file_name))
      dest_file = File.new(dest_file_path, "w")
      line_count = 0
      file_arr = []
      File.foreach(file_name) do |line| 
        if line_count > 0 and line_count < 3
          file_arr << line.chomp
        else
          file_arr << line
        end
        line_count += 1
      end
      file_arr.each do |line|
        dest_file.write(line)
      end
      dest_file.close
    end  
  end

  class SurfacePressureProcess < BaseLocalFile
    def initialize
      super

      @redis_last_report_time_key = "exchange_surface_pressure_last_report_time"
    end

    def file_format
      ".*"
    end

    def get_report_time_string file_name
      File.ctime(file_name).strftime("%Y%m%d%H%M%S")
    end

    def parse file_name
      FileUtils.makedirs(@dest_folder) unless File.exist?(@dest_folder)
      dest_file_path = File.join(@dest_folder, File.basename(file_name))
      dest_file = File.new(dest_file_path, "w")
      line_count = 0
      file_arr = []
      File.foreach(file_name) do |line| 
        if line_count > 0 and line_count < 3
          file_arr << line.chomp
        else
          file_arr << line
        end
        line_count += 1
      end
      file_arr.each do |line|
        dest_file.write(line)
      end
      dest_file.close
    end  
  end
end
