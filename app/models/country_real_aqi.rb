# == Schema Information
#
# Table name: country_real_aqis
#
#  id                :integer          not null, primary key
#  datetime          :datetime
#  area              :string(255)
#  position_name     :string(255)
#  station_code      :string(255)
#  primary_pollutant :string(255)
#  quality           :string(255)
#  aqi               :float(24)
#  co                :float(24)
#  co_24h            :float(24)
#  no2               :float(24)
#  no2_24h           :float(24)
#  o3                :float(24)
#  o3_24h            :float(24)
#  o3_8h             :float(24)
#  o3_8h_24h         :float(24)
#  pm10              :float(24)
#  pm10_24h          :float(24)
#  pm2_5             :float(24)
#  pm2_5_24h         :float(24)
#  so2               :float(24)
#  so2_24h           :float(24)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class CountryRealAqi < ActiveRecord::Base

  def as_json(options=nil)
    {
      datetime: (datetime - 8.hour).strftime("%Y-%m-%d %H"),
      area: area,
      position_name: position_name,
      primary_pollutant: primary_pollutant,
      quality: quality,
      aqi: aqi
    }
  end

  def self.process
    p "#{Time.now}: process country real aqi task"
    CountryRealAqiProcess.new.fetch
    clear_cache
  end

  def self.clear_cache
    last_time = $redis.get("country_real_aqis_last_time")
    keys = $redis.keys "country_real_aqis/*"
    keys.each do |item|
      $redis.del item unless item.split("/")[-2].eql?(last_time)
    end
  end

  class CountryRealAqiProcess
    DATA_URL = "http://www.pm25.in/api/querys/all_cities.json"

    def fetch
      conn = Faraday.new(:url => "http://www.pm25.in") do |faraday|
        faraday.request  :url_encoded
        # faraday.response :logger
        faraday.adapter  Faraday.default_adapter
      end

      response = conn.get DATA_URL, { token: Settings.CountryRealAqi.token }

      content = MultiJson.load response.body

      return if content.class.to_s.eql?("Hash")

      @redis_time = Time.now.strftime('%Y%m%d%H')
      last_report_time = $redis.get("country_real_aqis_last_time")
      content.each do |station_hash|
        time_point = station_hash['time_point']
        datetime = Time.parse(time_point)
        position_name = station_hash['position_name']
        item = CountryRealAqi.find_or_create_by datetime: datetime, position_name: position_name
        item.area = filter_name station_hash['area']
        item.station_code = station_hash['station_code']
        item.primary_pollutant = station_hash['primary_pollutant']
        item.quality = station_hash['quality']
        item.aqi = station_hash['aqi']
        item.co = station_hash['co']
        item.co_24h = station_hash['co_24h']
        item.no2 = station_hash['no2']
        item.no2_24h = station_hash['no2_24h']
        item.o3 = station_hash['o3']
        item.o3_24h = station_hash['o3_24h']
        item.o3_8h = station_hash['o3_8h']
        item.o3_8h_24h = station_hash['o3_8h_24h']
        item.pm10 = station_hash['pm10']
        item.pm10_24h = station_hash['pm10_24h']
        item.pm2_5 = station_hash['pm2_5']
        item.pm2_5_24h = station_hash['pm2_5_24h']
        item.so2 = station_hash['so2']
        item.so2_24h = station_hash['so2_24h']
        item.save

        write_to_cache(last_report_time, item)
      end
      $redis.set "country_real_aqis_last_time", "#{@redis_time}"
    end

    def write_to_cache(last_report_time, item)
      old_item = $redis.hget "country_real_aqis/#{last_report_time}/#{item.area}", "#{item.position_name}"
      old_item = MultiJson.load old_item rescue {}

      if old_item.nil? or Time.parse(old_item["datetime"]) < item.datetime
        $redis.hset "country_real_aqis/#{@redis_time}/#{item.area}", "#{item.position_name}", item.to_json
      end
    end

    # def after_process
    #   @process_result_info["end_time"] = DateTime.now.to_f
    #   push_task_log @process_result_info.to_json
    # end

    def filter_name(name)
      name = name.delete("地区")
      if name.length > 2 and name.include?("州")
        name = name.delete("州")
      end
      name
    end
  end
end
