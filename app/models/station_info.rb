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
      site_type: site_type,
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
    city_hash = MultiJson.load $redis.hget("city_infos", city_code) rescue {}
  end
end
