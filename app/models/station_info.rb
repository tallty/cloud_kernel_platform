# == Schema Information
#
# Table name: station_infos
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  alias_name  :string(255)
#  site_number :string(255)
#  district    :string(255)
#  address     :string(255)
#  lon         :float(24)
#  lat         :float(24)
#  high        :float(24)
#  province    :string(255)
#  site_type   :string(255)
#  subjection  :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class StationInfo < ActiveRecord::Base

  def as_json(options=nil)
    {
      site_number: site_number,
      name: alias_name,
      district: district,
      site_type: site_type,
      lon: lon,
      lat: lat,
      province: province,
      subjection: subjection
    }
  end

  def write_to_redis
    $redis.del "station_infos"
    station_infos = StationInfo.all
    station_infos.each do |station|
      $redis.hset "station_infos", station.site_number, station.to_json
    end
  end

  def self.find_by_redis site_number
    station_hash = MultiJson.load($redis.hget("station_infos", site_number)) rescue {}
    station = StationInfo.new station_hash
  end

  def self.find_city_from_redis site_number
    MultiJson.load $redis.hget("city_infos", site_number) rescue {}
  end

  def self.find_nearest_city(jd, wd)
    city_infos = $redis.hvals "city_infos"
    min_len = 1000
    min_len_city_name = ""
    min_len_city_code = ""
    city_infos.map do |city|
      city_hash = MultiJson.load city
      if city_hash["lon"].present? and city_hash["lat"].present?
        len = Math.hypot(jd - city_hash["lon"].to_f, wd - city_hash["lat"].to_f)
        if len < min_len
          min_len = len
          min_len_city_name = city_hash["name"]
          min_len_city_code = city_hash["code"]
        end
      end
    end
    nearest_city = { :nearest_city_code => min_len_city_code, :nearest_city_name => min_len_city_name, :min_len => min_len }
  end
end
