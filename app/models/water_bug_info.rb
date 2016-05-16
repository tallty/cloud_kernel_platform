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
#

class WaterBugInfo < ActiveRecord::Base

  def as_json(options=nil)
    {
      id: id,
      name: name,
      lon: lon,
      lat: lat
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

end
