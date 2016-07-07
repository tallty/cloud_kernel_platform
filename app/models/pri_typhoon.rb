# == Schema Information
#
# Table name: pri_typhoons
#
#  id               :integer          not null, primary key
#  serial_number    :string(255)
#  last_report_time :datetime
#  cname            :string(255)
#  ename            :string(255)
#  year             :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class PriTyphoon < ActiveRecord::Base
  has_many :pri_typhoon_items
  
  def self.process
    PriTyphoon::PriTyphoonProcess.new.fetch('201601')
  end

  class PriTyphoonProcess
    include NetworkMiddleware

    def initialize
      @root = self.class.to_s
      super
    end

    def fetch idx
      params_hash = {
        method: 'post',
        data: {tfbh: idx}
      }
      
      result = get_data(params_hash, {})
      typhoon_info = result['tfbh']
      typhoon = PriTyphoon.find_or_create_by serial_number: typhoon_info['TFBH'][-4, 4]
      typhoon.cname = typhoon_info['TFM']
      typhoon.ename = typhoon_info['TFME']
      typhoon.year = typhoon_info['TFBH'][0, 4]
      
      real_location = result['tflslj']
      last_real_max_wind = 0
      last_forecast_time = {}
      real_location.each do |item|
        _item = typhoon.pri_typhoon_items.find_or_create_by info: 0, cur_time: Time.zone.parse(item['RQSJ'])
        _item.lon = item['JD']
        _item.lat = item['WD']
        _item.min_pressure = item['ZXQY']
        _item.max_wind = item['ZXFS']
        _item.move_speed = item['YDSD']
        _item.move_direction = item['YDFX']
        _item.seven_radius = item['RADIUS7']
        _item.ten_radius = item['RADIUS10']
        typhoon.last_report_time = _item.cur_time
        last_real_max_wind = _item.max_wind
        _item.save
      end
      typhoon.save
      forecast_location = result['tfyblj']
      forecast_location.each do |item|
        _item = typhoon.pri_typhoon_items.find_or_create_by info: 1, cur_time: Time.zone.parse(item['RQSJ']), report_time: Time.zone.parse(item['YBSJ']), unit: item['TM']
        _item.lon = item['JD']
        _item.lat = item['WD']
        _item.min_pressure = item['ZXQY']
        _item.max_wind = item['ZXFS']
        _item.move_speed = item['YDSD']
        _item.move_direction = item['YDFX']
        _item.seven_radius = item['RADIUS7']
        _item.ten_radius = item['RADIUS10']
        last_forecast_time[_item.unit] = _item.report_time
        _item.save
      end
      
      _forecast_location = typhoon.pri_typhoon_items.where(info: 1).order(cur_time: :asc).group_by {|item| item.unit}
      forecast_location = {}
      _forecast_location.each do |key, items|
        items.each do |item|
          if item.report_time == last_forecast_time[key]
            forecast_location[key] ||= []
            forecast_location[key] << item
          end
        end
      end
      json_result = {
        name: typhoon.serial_number,
        cname: typhoon.cname,
        ename: typhoon.ename,
        last_report_time: typhoon.last_report_time.strftime("%F %H:%M"),
        level: last_real_max_wind,
        real_location: typhoon.pri_typhoon_items.where(info: 0),
        forecast_location: forecast_location
      }
      $redis.hset "pri_typhoon_cache", typhoon.serial_number, json_result.to_json
      nil
    end
  end
end
