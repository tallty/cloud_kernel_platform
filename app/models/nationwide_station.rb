class NationwideStation < ActiveRecord::Base
  has_many :nationwide_station_items

  def as_json(options=nil)
    {
      report_date: report_date.strftime("%Y-%m-%d %H:00"),
      items: nationwide_station_items.to_json
    }
  end

  def self.process
    NationwideStationProcess.new.process
  end

  class NationwideStationProcess
    def initialize
      @data_source = Settings.NationwideStation.source
      @redis_key = "nationwide_stations"
      @redis_last_report_time_key = "nationwide_station_last_report_time"

    end

    def process
      content = get_data
      ds = content["DS"]
      report_time_string = ds.first["Datetime"]
      report_time = Time.parse(report_time_string) + 8.hour
      group = NationwideStation.find_or_create_by report_date: report_time

      ds.each do |obj|
        sitenumber = obj["Station_Id_C"]
        city = StationInfo.find_city_from_redis sitenumber
        if city.present?
          item = group.nationwide_station_items.find_or_create_by report_date: report_time, sitenumber: sitenumber.to_s
          item.city_name = city["name"]
          item.tempe = obj['TEM'].to_f
          item.rain = obj['PRE'].to_f
          item.wind_direction = obj['WIN_D_INST'].to_f
          item.wind_speed = obj['WIN_S_INST'].to_f
          item.visibility = obj['VIS_HOR_1MI'].to_f
          item.pressure = obj['PRS'].to_f
          item.humi = obj['RHU'].to_f
          $redis.hset "#{@redis_key}", item.city_name.sub(/市|新区|区|县|乡|镇/, ''), item.to_json
          
          item.save
        else
          p obj
        end
      end
      nil
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
      response = conn.get "#{@data_source}/cimiss-web/api", { userId: 'BCSH_SMSSC_kjfwzx',
                                                                    pwd: 'kjfwzx', interfaceId: 'getAllStationDataBytimes',
                                                                    minStaid: '50134', maxStaid: '59985',
                                                                    elements: 'Datetime,Station_Id_C,PRE,TEM,WIN_D_INST,WIN_S_INST,VIS_HOR_1MI,PRS,RHU',
                                                                    timeRange: "(#{from_datetime},#{to_datetime})",
                                                                    orderby: 'Station_ID_C:ASC',
                                                                    dataCode: 'SURF_CHN_MUL_HOR_N', dataFormat: 'json' }

      content = MultiJson.load response.body
    end
  end

end
