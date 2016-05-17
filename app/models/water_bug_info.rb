# == Schema Information
#
# Table name: water_bug_infos
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  lon        :float(24)
#  lat        :float(24)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  baidu_lon  :float(24)
#  baidu_lat  :float(24)
#

class WaterBugInfo < ActiveRecord::Base

  def as_json(options=nil)
    {
      id: id,
      name: name,
      lon: baidu_lon,
      lat: baidu_lat
    }
  end
  
  def read_from_file
    File.foreach('./data/water_bug_infos.txt') do |line|
      line     = line.strip
      contents = line.split(' ')
      item = WaterBugInfo.find_or_create_by(name: contents[0])
      item.lon = contents[-2].to_f
      item.lat = contents[-1].to_f
      item.save
      $redis.hset "water_bug_infos", item.name, item.to_json
    end
  end

  def fix_baidu_location
    WaterBugInfo.all.each do |info|
      result = baidu_api info.lon, info.lat
      baidu_location = result['result'][0]
      info.update_attributes(baidu_lon: baidu_location['x'], baidu_lat: baidu_location['y'])
      $redis.hset "water_bug_infos", item.name, item.to_json
    end
  end

  private
  # http://api.map.baidu.com/geoconv/v1/?coords=114.21892734521,29.575429778924;114.21892734521,29.575429778924&from=1&to=5&ak=200aadcf1ccf720749c79228f9b7fd79
  def baidu_api lon, lat
    conn = Faraday.new(:url => 'http://api.map.baidu.com') do |faraday|
      faraday.request  :url_encoded
      faraday.response :logger
      faraday.adapter  Faraday.default_adapter
    end

    # 提交任务处理情况
    response = conn.get "http://api.map.baidu.com/geoconv/v1/", {from: 1, to: 5, ak: '200aadcf1ccf720749c79228f9b7fd79', coords: "#{lon},#{lat}"}
    MultiJson.load(response.body) rescue {}
  end
end
