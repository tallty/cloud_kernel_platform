# == Schema Information
#
# Table name: typhoon_items
#
#  id           :integer          not null, primary key
#  location     :string(255)
#  report_time  :datetime
#  effective    :integer
#  lon          :float(24)
#  lat          :float(24)
#  max_wind     :float(24)
#  min_pressure :float(24)
#  seven_radius :float(24)
#  ten_radius   :float(24)
#  direct       :float(24)
#  speed        :float(24)
#  typhoon_id   :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#

class TyphoonItem < ActiveRecord::Base
  belongs_to :typhoon

  default_scope { order(:updated_at, :asc) }

  def as_json options=nil
    {
      report_time: (report_time - 8.hour).strftime('%Y%m%d%H'),
      effective: effective,
      lon: lon,
      lat: lat,
      max_wind: max_wind,
      min_pressure: min_pressure,
      seven_radius: seven_radius,
      ten_radius: ten_radius,
      direct: direct,
      speed: speed
    }
  end
  
  # 返回字段为CSV格式，每一行一条记录，中间以英文逗号(,)隔开
  # 每行的对应的值依次为
  # id,typhoonid,pathtime,longitude,latitude,hours,centerairpressure,maxwindspeed,moveheading,movespeeding,centersevenradius,centertenradius
  # 30458,1211,2012/8/4 20:00:00,120.9,28.8,72,968,35,0,0,0,0
  def to_s
    report_time_string = report_time.strftime('%Y/%m/%d %H:%M:%S')
    effective_str = effective == 0 ? "00" : effective.to_s
    "#{id},#{typhoon.name},#{report_time_string},#{lon},#{lat},#{effective_str},#{min_pressure},#{max_wind},#{direct},#{speed},#{seven_radius},#{ten_radius},#{typhoon.location.downcase}"
  end
end
