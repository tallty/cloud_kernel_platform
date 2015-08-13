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
end
