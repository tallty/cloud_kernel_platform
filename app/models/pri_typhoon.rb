# == Schema Information
#
# Table name: pri_typhoons
#
#  id               :integer          not null, primary key
#  serial_number    :string
#  last_report_time :datetime
#  cname            :string
#  ename            :string
#  year             :integer
#  status           :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class PriTyphoon < ActiveRecord::Base
  enum status: { stop: 0, active: 1 }

  has_many :pri_typhoon_items, autosave: false

  def as_json(_options=nil)
    {
      serial_number: serial_number,
      ename: ename,
      cname: cname,
      status: status,
      last_report_time: last_report_time.strftime("%F %H:%M:%S")
    }
  end

  def self.process
    get_typhoon_list
    refresh_typhoon_list
  end

  def refresh_detail
    tfid = "20#{serial_number}"
    url = "http://typhoon.zjwater.gov.cn/Api/TyphoonInfo/#{tfid}"
    response = Faraday.get url
    result = MultiJson.load response.body
    real_points = fetch_real_points result
    forecast_set = fetch_forecast_set result
    update(last_report_time: real_points.last.cur_time)
    json_hash = self.as_json.merge(
      {
        real_location: real_points,
        forecast_location: forecast_set,
        level: real_points.last.max_wind,
      }
    )
    $redis.hset "pri_typhoon_cache", serial_number, json_hash.to_json
  end

  private
    def self.refresh_typhoon_list
      list = PriTyphoon.where("year > ?", DateTime.now.year - 2).order(serial_number: :desc)
      $redis.set("pri_typhoon_list_cache", list.to_json)
    end

    def self.get_typhoon_list
      year = DateTime.now.year
      url = "http://typhoon.zjwater.gov.cn/Api/TyphoonList/#{year}"
      response = Faraday.get url
      typhoons = MultiJson.load(response.body)
      typhoons.each do |item|
        serial_number = item['tfid'][-4, 4]
        typhoon = PriTyphoon.find_by(serial_number: serial_number)
        if typhoon.blank?
          typhoon = PriTyphoon.create(
            serial_number: serial_number,
            year: year,
          )
        end
        is_current = item['isactive'].to_i
        typhoon.update_attributes(
          status: is_current,
          cname: item['name'],
          ename: item['enname'],
        )
        typhoon.refresh_detail item if is_current == 1
      end
    end

    def fetch_real_points result
      result.first['points'].map do |item|
        pri_typhoon_items.new(
          info: 0,
          cur_time: Time.zone.parse(item['time']),
          lon: item['lng'],
          lat: item['lat'],
          min_pressure: item['pressure'],
          max_wind: item['speed'],
          move_speed: item['movespeed'],
          move_direction: item['movedirection'],
          seven_radius: item['radius7'],
          ten_radius: item['radius10'],
        )
      end
    end

    def fetch_forecast_set result
      last_point = result.first['points'].last
      (last_point['forecast'] || []).map do |forecast|
        {
          forecast['tm'] => forecast['forecastpoints'].map do |item|
            next if Time.zone.parse(item['time']) < Time.zone.now
            pri_typhoon_items.new(
              info: 0,
              cur_time: Time.zone.parse(item['time']),
              unit:  forecast['tm'],
              lon: item['lng'],
              lat: item['lat'],
              min_pressure: item['pressure'],
              max_wind: item['speed'],
            )
          end
        }
      end.push{
        { '上海' => fetch_shanghai_forecast_points }
      }
    end

    def fetch_shanghai_forecast_points
      sh_typhoon = Typhoon.where(name: serial_number, location: 'bcsh').first
      if sh_typhoon.present?
        last_point = sh_typhoon.typhoon_items.where(effective: 0).last
        sh_typhoon_forecast = sh_typhoon.typhoon_items.where("id > ?", last_point.id)
        sh_typhoon_forecast.map do |item|
          {
            report_time: item.report_time,
            time: item.report_time.strftime("%Y年%m月%d日 %H时"),
            unit: '上海',
            lon: item.lon,
            lat: item.lat,
            max_wind: item.max_wind,
            min_pressure: item.min_pressure,
            seven_radius: item.seven_radius,
            ten_radius: item.ten_radius,
            direct: item.direct,
            speed: item.speed,
          }
        end
      end
    end
end
