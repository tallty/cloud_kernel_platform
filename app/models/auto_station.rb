class AutoStation < ActiveRecord::Base
  establish_connection :old_database
  self.table_name = "auto_stations"

  scope :max_tempe_all_station, -> { where("datetime > ? and datetime <= ?", (Time.zone.now.to_date - 2.day).strftime("%Y%m%d2000"), (Time.zone.now.to_date - 1.day).strftime("%Y%m%d2000")).group(:sitenumber).maximum(:max_tempe) }
  scope :min_tempe_all_station, -> { where("datetime > ? and datetime <= ?", (Time.zone.now.to_date - 2.day).strftime("%Y%m%d2000"), (Time.zone.now.to_date - 1.day).strftime("%Y%m%d2000")).group(:sitenumber).minimum(:min_tempe) }

  scope :max_tempe_main_district, -> { where("datetime > ? and datetime <= ? and sitenumber in (?)", (Time.zone.now.to_date - 2.day).strftime("%Y%m%d2000"), (Time.zone.now.to_date - 1.day).strftime("%Y%m%d2000"), ["58361", "58362","58365","58460","58461","58462","58463","58366","58367","58370"]).group(:sitenumber).maximum(:max_tempe) }
  scope :min_tempe_main_district, -> { where("datetime > ? and datetime <= ? and sitenumber in (?)", (Time.zone.now.to_date - 2.day).strftime("%Y%m%d2000"), (Time.zone.now.to_date - 1.day).strftime("%Y%m%d2000"), ["58361", "58362","58365","58460","58461","58462","58463","58366","58367","58370"]).group(:sitenumber).minimum(:min_tempe) }

  scope :hour_tempe_all_station, -> { where("datetime = ?", Time.zone.now.strftime("%Y%m%d%H00")).group(:sitenumber).pluck(:sitenumber, :tempe) }

  scope :all_day_rain, -> { where("datetime > ? and datetime <= ? and RIGHT(datetime, 4) = '0000'", (Time.zone.now.to_date - 2.day).strftime("%Y%m%d2000"), (Time.zone.now.to_date - 1.day).strftime("%Y%m%d2000")).group(:sitenumber).sum(:rain) }

  scope :hour_rain, -> { where("datetime = ?", Time.zone.now.strftime("%Y%m%d%H00")).pluck(:sitenumber, :rain)}
  scope :hour_min_visibility, -> { where("datetime like ? and visibility <> '////'", "#{Time.zone.now.strftime('%Y%m%d%H')}%").group(:sitenumber).minimum(:visibility) }
  scope :hour_max_win_speed, ->  { where("datetime like ? and max_speed <> '////'", "#{Time.zone.now.strftime('%Y%m%d%H')}%").group(:sitenumber).maximum(:max_speed) }
  
  scope :average_tempe, -> (day) { where("datetime in ('#{day}0200', '#{day}0800', '#{day}1400', #{day}2000)").group(:sitenumber).average(:tempe) }
  #
  # scope add time param
  scope :hour_rain_by_time, ->(time) { where("datetime = ?", time.strftime("%Y%m%d%H00")).pluck(:sitenumber, :rain)}
  scope :hour_min_visibility_by_time, ->(time) { where("datetime like ? and visibility <> '////'", "#{time.strftime('%Y%m%d%H')}%").group(:sitenumber).minimum(:visibility) }
  scope :hour_max_win_speed_by_time, ->(time)  { where("datetime like ? and max_speed <> '////'", "#{time.strftime('%Y%m%d%H')}%").group(:sitenumber).maximum(:max_speed) }
  scope :hour_tempe_all_station_by_time, ->(time) { where("datetime = ?", time.strftime("%Y%m%d%H00")).group(:sitenumber).pluck(:sitenumber, :tempe) }

  def clear_redis
    # auto_stations/201503130720
    items = $redis.keys("auto_stations/*")  
    time = nil
    now_date = Time.now.to_date
    items.each do |key|
      time = Time.parse(key.split('/')[-1]) rescue next
      if now_date - 1.month > time
        $redis.del key
      end
    end
    items.clear
    time = nil
  end

  class TaskProcess < BaseTask
    def initialize
      super
    end

    def process(day=nil)
      date = day.present? ? day : DateTime.now.strftime('%Y%m%d')
      stations = AutoStation.average_tempe(date)
      FileUtils.makedirs(@local_dir) unless File.exist?(@local_dir)
      file_name = "#{@local_dir}/#{date}.txt"
      file = File.new(file_name, "w+")
      stations.each do |station|
        station_info = StationInfo.find_by_redis station[0]
        unless station_info.nil?
          if station_info.lon.present? and station_info.lat.present?
            file.puts "#{station_info.lon},#{station_info.lat},#{station[1].to_f.round(1)}\r\n"
          end
        end
      end
      file.close
      stations.clear
      
      send_file_by_ftp file_name
    end
  end

  class DataProcess

    def day_process
      now_date = (Time.now.to_date - 1.day)
      datas = AutoStation.max_tempe_all_station
      write_data_to_excel(datas, "#{now_date.strftime('%y年%m月%d日20点')} 全市自动站最高温度", "sh/station/tmaxall", "#{now_date.strftime('%y%m%d')}20")

      datas = AutoStation.min_tempe_all_station
      write_data_to_excel(datas, "#{now_date.strftime('%y年%m月%d日20点')} 全市自动站最低温度", "sh/station/tminall", "#{now_date.strftime('%y%m%d')}20")

      datas = AutoStation.max_tempe_main_district
      write_data_to_excel(datas, "#{now_date.strftime('%y年%m月%d日20点')} 各区县主站最高温度", "sh/station/tmaxday", "#{now_date.strftime('%y%m%d')}20")

      datas = AutoStation.min_tempe_main_district
      write_data_to_excel(datas, "#{now_date.strftime('%y年%m月%d日20点')} 各区县主站最低温度", "sh/station/tminday", "#{now_date.strftime('%y%m%d')}20")

      datas = AutoStation.all_day_rain
      write_data_to_excel(datas, "#{now_date.strftime('%y年%m月%d日20点')} 全天雨量累积", "sh/station/rainday", "#{now_date.strftime('%y%m%d')}20")

    end

    def hour_process
      now_date = Time.now
      format_date = now_date.strftime("%y年%m月%d日 %H时")
      datas = AutoStation.hour_rain
      write_data_to_excel(datas, "#{format_date} 全市自动站逐小时雨量", "sh/station/rainhour", "#{now_date.strftime('%y%m%d%H')}")
      datas = AutoStation.hour_min_visibility
      write_data_to_excel(datas, "#{format_date} 全市自动站最低能见度", "sh/station/vid", "#{now_date.strftime('%y%m%d%H')}")
      datas = AutoStation.hour_max_win_speed
      write_data_to_excel(datas, "#{format_date} 全市自动站最大风速", "sh/station/wind", "#{now_date.strftime('%y%m%d%H')}")
      datas = AutoStation.hour_tempe_all_station
      write_data_to_excel(datas, "#{format_date} 全市自动站逐小时温度", "sh/station/temphour", "#{now_date.strftime('%y%m%d%H')}")
    end

    def hour_process_by_time time
      format_date = time.strftime("%y年%m月%d日 %H时")
      datas = AutoStation.hour_rain_by_time(time)
      write_data_to_excel(datas, "#{format_date} 全市自动站逐小时雨量", "sh/station/rainhour", "#{now_date.strftime('%y%m%d%H')}")
      datas = AutoStation.hour_min_visibility_by_time(time)
      write_data_to_excel(datas, "#{format_date} 全市自动站最低能见度", "sh/station/vid", "#{now_date.strftime('%y%m%d%H')}")
      datas = AutoStation.hour_max_win_speed_by_time(time)
      write_data_to_excel(datas, "#{format_date} 全市自动站最大风速", "sh/station/wind", "#{now_date.strftime('%y%m%d%H')}")
      datas = AutoStation.hour_tempe_all_station_by_time(time)
      write_data_to_excel(datas, "#{format_date} 全市自动站逐小时温度", "sh/station/temphour", "#{now_date.strftime('%y%m%d%H')}")
    end

    def write_data_to_excel(datas, type, dir, filename)
      Axlsx::Package.new do |p|
        p.workbook.add_worksheet(:name => "#{filename}") do |sheet|
          sheet.add_row ["#{type}"]
          sheet.merge_cells("A1:D1")

          datas.map do |e, v|
            next if v.eql?('////')
            stationInfo = StationInfo.find_by_redis e
            next if stationInfo.lon.nil? or stationInfo.lat.nil?
            sheet.add_row [e, stationInfo.lon, stationInfo.lat, v]
          end

        end
        folder = File.join("/home/deploy/ftp/weathers/", dir)
        FileUtils.mkdir(folder) unless File.exist?(folder)
        p.serialize("#{folder}/#{filename}.xlsx")
      end
    end
  end
end
