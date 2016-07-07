# == Schema Information
#
# Table name: pri_typhoon_items
#
#  id             :integer          not null, primary key
#  report_time    :datetime
#  cur_time       :datetime
#  lon            :float(24)
#  lat            :float(24)
#  min_pressure   :float(24)
#  max_wind       :float(24)
#  move_speed     :float(24)
#  move_direction :float(24)
#  seven_radius   :float(24)
#  ten_radius     :float(24)
#  unit           :string(255)
#  info           :integer
#  pri_typhoon_id :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class PriTyphoonItem < ActiveRecord::Base
  belongs_to :pri_typhoon

  def as_json(options=nil)
    {
      report_time: cur_time,
      time: cur_time.strftime("%Y年%m月%d日 %H时"),
      lon: lon,
      lat: lat,
      max_wind: max_wind,
      min_pressure: min_pressure,
      seven_radius: seven_radius,
      ten_radius: ten_radius,
      direct: move_direction,
      speed: move_speed
    }
  end

  def as_group_json(options=nil)
    {

    }
  end
end
