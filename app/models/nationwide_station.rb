class NationwideStation < ActiveRecord::Base
  has_many :nationwide_station_items

  def as_json(options=nil)
    {
      report_date: report_date.strftime("%Y-%m-%d %H:00"),
      items: nationwide_station_items.to_json
    }
  end

  def self.process

  end

  class NationwideStationProcess
    def initialize
      @data_source = Settings.NationwideStation.source
      @redis_key = "nationwide_stations"
      @redis_last_report_time_key = "nationwide_station_last_report_time"

    end

    def process
      content = get_data
      p content
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
                                                                    timeRange: "(#{from_datetime,to_datetime})",
                                                                    orderby: 'Station_ID_C:ASC',
                                                                    dataCode: 'SURF_CHN_MUL_HOR_N', dataFormat: 'json' }

      content = MultiJson.load response.body
    end
  end

end
