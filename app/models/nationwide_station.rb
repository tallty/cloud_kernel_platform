# == Schema Information
#
# Table name: nationwide_stations
#
#  id          :integer          not null, primary key
#  report_date :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class NationwideStation < ActiveRecord::Base
  has_many :nationwide_station_items

  def as_json(options=nil)
    {
      report_date: report_date.strftime("%Y-%m-%d %H:00"),
      items: nationwide_station_items.to_json
    }
  end

  def process
    NationwideStationProcess.new.process
  end

  class NationwideStationProcess
    def initialize
      @data_source                = Settings.NationwideStation.source
      @redis_key                  = "nationwide_stations"
      @redis_last_report_time_key = "nationwide_station_last_report_time"

      @process_file_infos = []
      @process_result_info = { :start_time => Time.now.to_f }
    end

    def process
      content = get_data
      ds = content["DS"]
      report_time_string = ds.first["Datetime"]
      report_time = Time.parse(report_time_string) + 8.hour
      group = NationwideStation.find_or_create_by report_date: report_time

      count = 0
      datas = []
      ds.each do |obj|
        sitenumber = obj["Station_Id_C"]
        city = StationInfo.find_city_from_redis sitenumber
        if city.present?
          item = group.nationwide_station_items.find_or_create_by report_date: report_time, sitenumber: sitenumber.to_s
          item.city_name      = city["name"]
          item.tempe          = obj['TEM'].to_f
          item.rain           = obj['PRE'].to_f
          item.wind_direction = obj['WIN_D_INST'].to_f
          item.wind_speed     = obj['WIN_S_INST'].to_f
          item.visibility     = obj['VIS_HOR_1MI'].to_f
          item.pressure       = obj['PRS'].to_f
          item.humi           = obj['RHU'].to_f
          $redis.hset "#{@redis_key}", item.city_name.sub(/市|新区|区|县|乡|镇/, ''), item.to_json

          item.save
          count += 1
          datas << [item.sitenumber, item.tempe]
        else
        end
      end

      format_date = report_time.strftime("%Y年%m月%d日 %H时")

      write_data_to_excel(datas, "#{format_date} 全国自动站逐小时温度", "hour_tmepe", "#{report_time.strftime('%Y%m%d%H%M')}.xlsx")
      @process_result_info["exception"] = ""
      @process_result_info["file_list"] = {:data => ds.size, :success => count}.to_json

      @process_result_info["end_time"] = DateTime.now.to_f
      ds.clear
      datas.clear
      after_process
    end

    def get_data
      conn = Faraday.new(:url => @data_source) do |faraday|
        faraday.request  :url_encoded
        # faraday.response :logger
        faraday.adapter  Faraday.default_adapter
      end
      now_time = Time.now
      from_datetime = (now_time - 9.hour).strftime("%Y%m%d%H0000")
      to_datetime = (now_time - 7.hour).strftime("%Y%m%d%H0000")
      response = conn.get "#{@data_source}/cimiss-web/api",
                            { userId: 'BCSH_SMSSC_kjfwzx',
                            pwd: 'kjfwzx',
                            interfaceId: 'getAllStationDataBytimes',
                            minStaid: '50134',
                            maxStaid: '59985',
                            elements: 'Datetime,Station_Id_C,PRE,TEM,WIN_D_INST,WIN_S_INST,VIS_HOR_1MI,PRS,RHU',
                            timeRange: "(#{from_datetime},#{to_datetime})",
                            orderby: 'Station_ID_C:ASC',
                            dataCode: 'SURF_CHN_MUL_HOR_N',
                            dataFormat: 'json' }

      content = MultiJson.load response.body
    end

    def after_process
      begin
        push_task_log
      rescue Exception => e
        Rails.logger.warn e.to_json
      end
    end

    def push_task_log
      conn = Faraday.new(:url => 'http://mcu.buoyantec.com') do |faraday|
        faraday.request  :url_encoded
        faraday.adapter  Faraday.default_adapter
      end
      Rails.logger.warn @process_result_info
      # 提交任务处理情况
      response = conn.post "http://mcu.buoyantec.com/task_logs/fetch", {task_log: { task_identifier: "vysJxTkG", process_result: @process_result_info } }
    end

    # 数据写入excel
    def write_data_to_excel(datas, type, dir, filename)
      datetime = Time.now.strftime('%y%m%d%')
      Axlsx::Package.new do |p|
        p.workbook.add_worksheet(:name => "#{datetime}") do |sheet|
          sheet.add_row ["#{type}"]
          sheet.merge_cells("A1:D1")

          datas.map do |e, v|
            next if v.eql?('////') or v.eql?(999999.0)
            city = $redis.hget "city_infos", e
            city_hash = MultiJson.load city rescue {}
            next if city_hash.try(:[], "lon").nil? or city_hash.try(:[], "lat").nil?
            sheet.add_row [e, city_hash["lon"], city_hash["lat"], v]
          end

        end

        FileUtils.mkdir("../ftp/weathers/country/tempe") unless File.exist?("../ftp/weathers/country/tempe")
        p.serialize("../ftp/weathers/country/tempe/#{filename}")
      end
    end

  end

end
