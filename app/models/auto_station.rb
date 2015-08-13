class AutoStation < ActiveRecord::Base
  establish_connection :auto_station

  scope :max_tempe_all_station, -> { where("datetime > ? and datetime < ?", (Time.zone.now.to_date - 2.day).strftime("%Y%m%d2000"), (Time.zone.now.to_date - 1.day).strftime("%Y%m%d2000")).group(:sitenumber).maximum(:max_tempe) }
  scope :min_tempe_all_station, -> { where("datetime > ? and datetime < ?", (Time.zone.now.to_date - 2.day).strftime("%Y%m%d2000"), (Time.zone.now.to_date - 1.day).strftime("%Y%m%d2000")).group(:sitenumber).minimum(:min_tempe) }

  scope :max_tempe_main_district, -> { where("datetime > ? and datetime < ? and sitenumber in (?)", (Time.zone.now.to_date - 2.day).strftime("%Y%m%d2000"), (Time.zone.now.to_date - 1.day).strftime("%Y%m%d2000"), ["58361", "58362","58365","58460","58461","58462","58463","58366","58367","58370"]).group(:sitenumber).maximum(:max_tempe) }
  scope :min_tempe_main_district, -> { where("datetime > ? and datetime < ? and sitenumber in (?)", (Time.zone.now.to_date - 2.day).strftime("%Y%m%d2000"), (Time.zone.now.to_date - 1.day).strftime("%Y%m%d2000"), ["58361", "58362","58365","58460","58461","58462","58463","58366","58367","58370"]).group(:sitenumber).minimum(:min_tempe) }

  scope :hour_tempe_all_station, -> { where("datetime = ?", Time.zone.now.strftime("%Y%m%d%H00")).group(:sitenumber).pluck(:sitenumber, :tempe) }

  scope :all_day_rain, -> { where("datetime > ? and datetime < ?", "201508062000", "201508072000").group(:sitenumber).sum(:rain) }

  # scope :min_visibility, -> { where("datetime = ?", (Time.zone.now - 1.hour).strftime("%Y%m%d%H%00")) }
  # scope :max_win_speed, -> { where () }
  #
  #

  class DataProcess

    def day_process
      now_date = (Time.zone.now.to_date - 1.day).strftime("%y-%m-%d")
      datas = AutoStation.max_tempe_all_station
      write_data_to_excel(datas, "#{now_date} 全市自动站最高温度", "sh\\station\\tmaxall", "#{now_date}.xlsx")

      datas = AutoStation.min_tempe_all_station
      write_data_to_excel(datas, "#{now_date} 全市自动站最低温度", "sh\\station\\tminall", "#{now_date}.xlsx")

      datas = AutoStation.max_tempe_main_district
      write_data_to_excel(datas, "#{now_date} 各区县主站最高温度", "sh\\station\\tmaxday", "#{now_date}.xlsx")

      datas = AutoStation.min_tempe_main_district
      write_data_to_excel(datas, "#{now_date} 各区县主站最低温度", "sh\\station\\tminday", "#{now_date}.xlsx")

      datas = AutoStation.all_day_rain
      write_data_to_excel(datas, "#{now_date} 全天雨量累积", "sh\\station\\rainday", "#{now_date}.xlsx")

    end

    def hour_process
      now_date = Time.zone.now
      format_date = now_date.strftime("%Y年%m月%d日 %H时")
      datas = AutoStation.hour_tempe_all_station
      write_data_to_excel(datas, "#{format_date} 全市自动站逐小时温度", "hour_tmepe", "#{now_date.strftime('%Y%m%d%H%M')}.xlsx")
    end

    def write_data_to_excel(datas, type, dir, filename)
      datetime = Time.zone.now.strftime('%y%m%d%')
      Axlsx::Package.new do |p|
        p.workbook.add_worksheet(:name => "#{datetime}") do |sheet|
          sheet.add_row ["#{type}"]
          sheet.merge_cells("A1:D1")

          datas.map do |e, v|
            next if v.eql?('////')
            stationInfo = ShStationInfo.find_by_redis e
            next if stationInfo.lon.nil? or stationInfo.lat.nil?
            sheet.add_row [e, stationInfo.lon, stationInfo.lat, v]
          end

        end
        folder = File.join("/home/deploy/ftp/weathers/", dir)
        FileUtils.mkdir(folder) unless File.exist?(folder)
        p.serialize("#{folder}/#{filename}")
      end
    end
  end
end
