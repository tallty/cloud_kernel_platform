# == Schema Information
#
# Table name: nationwide_station_items
#
#  id                    :integer          not null, primary key
#  report_date           :datetime
#  sitenumber            :string(255)
#  city_name             :string(255)
#  tempe                 :float(24)
#  rain                  :float(24)
#  wind_direction        :float(24)
#  wind_speed            :float(24)
#  visibility            :float(24)
#  pressure              :float(24)
#  humi                  :float(24)
#  nationwide_station_id :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#

class NationwideStationItem < ActiveRecord::Base
  belongs_to :nationwide_station

  def as_json options=nil
    {
      datetime: (report_date + 8.hour).strftime("%Y-%m-%d %H:00"),
      name: city_name,
      tempe: tempe,
      rain: rain,
      wind_direction: wind_direction,
      wind_speed: wind_speed,
      visibility: visibility,
      humi: humi,
      pressure: pressure
    }
  end
end
