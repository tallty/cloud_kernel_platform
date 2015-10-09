class NationwideStationItem < ActiveRecord::Base
  belongs_to :nationwide_station

  def as_json options=nil
    {
      datetime: report_date.strftime("%Y-%m-%d %H:%M"),
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
