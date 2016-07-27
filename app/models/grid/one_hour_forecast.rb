module Grid
  class OneHourForecast

    def self.process
      Grid::OneHourForecast::DataProcessor.new.process
    end

    def analyze
      File.open("./data/Z_GRID_TEMP_201607271400_SPCC_201607271100_02401", "r:binary") do |f|
        basename = "Z_GRID_TEMP_201607271400_SPCC_201607271100_02401"
        infos = basename.split("_")
        p "--------------------#{infos}----------------------------"
        type = infos[2].downcase
        s = f.read(48)
        head = s.unpack 'f*'
        p "起始经度: #{head[0].to_f}"
        p "经度格距: #{head[1].to_f.round(2)}"
        p "经向格点数: #{head[2].to_f}"
        p "起始纬度: #{head[3].to_f}"
        p "纬度格距: #{head[4].to_f.round(2)}"
        p "纬向格点数: #{head[5].to_f}"
        p "起始时次: #{head[6].to_f}"
        p "终止时次: #{head[7].to_f}"
        p "间隔时次: #{head[8].to_f}"
        lon_count = head[2].to_i
        lat_count = head[5].to_i
        time_count = (head[7] / head[6]).to_i
        grid_data_hash = {}
        arr = f.read.unpack 'f*'

        arr.each_with_index do |data, index|
          lon_index = index % lon_count
          lat_index = (index % (lon_count * lat_count)) / lon_count
          # p "lon_index: #{lon_index}, lat_index: #{lat_index}"
          time_index = index/(lon_count * lat_count)
          index_key = "#{lon_index}_#{lat_index}_#{time_index}"
          grid_data_hash[index_key] ||= {date_time: infos[5]}
          grid_data_hash[index_key][type.to_sym] = data.round(1)
          p grid_data_hash
        end
        nil
      end
    end

    class DataProcessor < BaseForecast
      def initialize
        super

        @redis_key = "one_hour_grid_forecast_cache"
        @redis_last_report_time_key = "one_hour_grid_forecast_last_report_time"
        @grid_data_hash = {}
      end

      protected
      def get_report_time_string filename
        report_time_string = filename.split(/_|\./)[-4]
      end

      def ftpfile_format day
        "Z_GRID_*_SPCC_#{to_date_string(day)}*_02401"
      end

      def parse local_file
        basename = File.basename local_file
        infos = basename.split('_')
        type = infos[2].downcase
        @update_time = infos[-2]
        File.open(local_file, "r:binary") do |f|
          head = s.unpack 'f*'
          lon_count = head[2].to_i
          lat_count = head[5].to_i
          time_count = (head[7] / head[6]).to_i
          arr = f.read.unpack 'f*'

          arr.each_with_index do |data, index|
            lon_index = index % lon_count
            lat_index = (index % (lon_count * lat_count)) / lon_count
            time_index = index/(lon_count * lat_count)
            index_key = "#{lon_index}_#{lat_index}_#{time_index}"
            @grid_data_hash[index_key] ||= {date_time: infos[5]}
            @grid_data_hash[index_key][type.to_sym] = data.round(1)
          end

        end
      end

      def after_process
        save_to_redis
      end

      private
      def save_to_redis
        if @grid_data_hash.present?
          @grid_data_hash.each do |k, v|
            $redis.hset "#{@redis_key}_#{@update_time}", k, v.to_json
          end
          @grid_data_hash.clear
        end
      end
    end
  end
end
