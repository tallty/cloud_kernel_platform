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

  def as_json(options=nil)
    {
      serial_number: serial_number,
      ename: ename,
      cname: cname,
      last_report_time: last_report_time.strftime("%F %H:%M:%S")
    }
  end
  def self.process
    get_now_typhoon
    refresh_typhoon_list
  end

  def self.refresh_typhoon_list
    list = PriTyphoon.where("year > ?", DateTime.now.year - 2).order(serial_number: :desc)
    $redis.set("pri_typhoon_list_cache", list.to_json)
  end

  def shutdown
    self.update_attributes(status: 0)
    # self.build_content
    typhoon = $redis.hget("pri_typhoon_cache", self.serial_number)
    typhoon_hash = MultiJson.load(typhoon)
    typhoon_hash["status"] = "stop"
    $redis.hset("pri_typhoon_cache", self.serial_number, typhoon_hash.to_json)
  end

  # def self.get_typhoon_list serial_number
  #   _year = DateTime.now.year
  #   params_hash = {year: _year}
  #   typhoons = PriTyphoon::PriTyphoonProcess.new.fetch params_hash
  #   now_typhoon = nil
  #   typhoons.each do |item|
  #     typhoon = PriTyphoon.find_or_create_by serial_number: item['TFBH'][-4, 4]
  #     typhoon.cname = item['TFM'] if typhoon.cname.blank?
  #     typhoon.ename = item['TFME'] if typhoon.ename.blank?
  #     typhoon.year = _year
  #     typhoon.save
  #     if typhoon.serial_number.eql?(serial_number)
  #       now_typhoon = typhoon
  #     end
  #   end
  #   now_typhoon
  # end

  # def self.refresh_history year
  #   params_hash = {year: year}
  #   typhoons = PriTyphoon::PriTyphoonProcess.new.fetch params_hash
  #   now_typhoon = nil
  #   typhoons.each do |item|
  #     typhoon = PriTyphoon.find_or_create_by serial_number: item['TFBH'][-4, 4]
  #     typhoon.cname = item['TFM'] if typhoon.cname.blank?
  #     typhoon.ename = item['TFME'] if typhoon.ename.blank?
  #     typhoon.year = year
  #     typhoon.save
  #     typhoon.refresh_typhoon_detail({"TFBH" => "20#{typhoon.serial_number}"})
  #   end
  # end

  # def self.get_now_typhoon
  #   typhoons = PriTyphoon::PriTyphoonProcess.new.fetch({action: 'nowtyphoon'})
  #   now_typhoons = []
  #   typhoons.each do |item|
  #     serial_number = item['TFBH'][-4, 4]
  #     typhoon = PriTyphoon.find_by(serial_number: serial_number)
  #     if typhoon.blank?
  #       typhoon = get_typhoon_list serial_number
  #     end
  #     typhoon.update_attributes(status: 1)
  #     typhoon.refresh_typhoon_detail item
  #     now_typhoons << serial_number
  #   end
  #   $redis.set "now_typhoons_cache", now_typhoons.join(',')
  # end

  # 20160912
  def self.get_now_typhoon
    _year = DateTime.now.year
    _host = "http://typhoon.zjwater.gov.cn"
    _url = "/Api/TyphoonList/#{params['tfbh']}"

    connect = Faraday.new(url: _host) do |faraday|
      faraday.request :url_encoded
      faraday.response :logger
      faraday.adapter Faraday.default_adapter
    end

    response = connect.get do |request|
      request.url _url
      request.headers['Content-Type'] = 'application/json'
      request.headers['Accept'] = 'application/json'
    end
    typhoons = MultiJson.load(response.body)
    typhoons.each do |item|
      serial_number = item['tfid'][-4, 4]
      typhoon = PriTyphoon.find_by(serial_number: serial_number)
      if typhoon.blank?
        typhoon = PriTyphoon.find_or_create_by serial_number: serial_number
        typhoon.cname = item['name'] if typhoon.cname.blank?
        typhoon.ename = item['enname'] if typhoon.ename.blank?
        typhoon.year = _year
        typhoon.save
      end
      is_current = item['isactive'].to_i
      typhoon.update_attributes(status: is_current)
      typhoon.refresh_typhoon_detail item if is_current == 1
    end
  end

  def refresh_typhoon_detail params

    _host = "http://typhoon.zjwater.gov.cn"
    _url = "/Api/TyphoonInfo/#{params['tfbh']}"

    connect = Faraday.new(url: _host) do |faraday|
      faraday.request :url_encoded
      faraday.response :logger
      faraday.adapter Faraday.default_adapter
    end

    response = connect.get do |request|
      request.url _url
      request.headers['Content-Type'] = 'application/json'
      request.headers['Accept'] = 'application/json'
    end
    result = MultiJson.load(response.body)

    real_location = result.first['points']

    last_forecast_time = {}
    last_report_time = nil
    real_location.each do |item|
      _item = pri_typhoon_items.find_or_create_by info: 0, cur_time: Time.zone.parse(item['time'])
      _item.lon = item['lng']
      _item.lat = item['lat']
      _item.min_pressure = item['pressure']
      _item.max_wind = item['speed']
      _item.move_speed = item['movespeed']
      _item.move_direction = item['movedirection']
      _item.seven_radius = item['radius7']
      _item.ten_radius = item['radius10']
      last_report_time = _item.cur_time
      _item.save
    end
    self.update_attributes(last_report_time: last_report_time)

    last_real_location = real_location.last
    forecast_sets = last_real_location['forecast'] || []
    forecast_sets.each do |forecast_set|
      unit = forecast_set['tm']
      forecast_location = forecast_set['forecastpoints']
      forecast_location.each do |item|
        _cur_time = Time.zone.parse(item['time'])
        _report_time = Time.zone.parse(last_real_location['time'])
        # 如果预报的时间比当前点时间还早，就去掉这个预报
        next if _cur_time <= _report_time
        _item = pri_typhoon_items.find_or_create_by info: 1, cur_time: _cur_time, report_time: _report_time, unit: unit
        _item.lon = item['lng']
        _item.lat = item['lat']
        _item.min_pressure = item['pressure']
        _item.max_wind = item['speed']
        # _item.move_speed = item['move_speed']
        # _item.move_direction = item['move_dir']
        # _item.seven_radius = item['radius7']
        # _item.ten_radius = item['radius10']
        last_forecast_time[_item.unit] = _item.report_time
        _item.save
      end
    end
    

    build_content last_forecast_time

    nil
  end


  # def refresh_typhoon_detail params
  #   result = PriTyphoon::PriTyphoonProcess.new.fetch params

  #   # typhoon_info = result['tfbh']
  #   # typhoon = PriTyphoon.find_or_create_by serial_number: typhoon_info['TFBH'][-4, 4]
  #   # reutrn if typhoon.try(:status) == 1
  #   # typhoon.cname = typhoon_info['TFM'] if typhoon.cname.blank?
  #   # typhoon.ename = typhoon_info['TFME'] if typhoon.ename.blank?
  #   # typhoon.year = typhoon_info['TFBH'][0, 4]

  #   real_location = result['tflslj']

  #   last_forecast_time = {}
  #   last_report_time = nil
  #   real_location.each do |item|
  #     _item = pri_typhoon_items.find_or_create_by info: 0, cur_time: Time.zone.parse(item['RQSJ'])
  #     _item.lon = item['JD']
  #     _item.lat = item['WD']
  #     _item.min_pressure = item['ZXQY']
  #     _item.max_wind = item['ZXFS']
  #     _item.move_speed = item['YDSD']
  #     _item.move_direction = item['YDFX']
  #     _item.seven_radius = item['RADIUS7']
  #     _item.ten_radius = item['RADIUS10']
  #     last_report_time = _item.cur_time
  #     _item.save
  #   end
  #   self.update_attributes(last_report_time: last_report_time)

  #   forecast_location = result['tfyblj']
  #   forecast_location.each do |item|
  #     _item = pri_typhoon_items.find_or_create_by info: 1, cur_time: Time.zone.parse(item['RQSJ']), report_time: Time.zone.parse(item['YBSJ']), unit: item['TM']
  #     _item.lon = item['JD']
  #     _item.lat = item['WD']
  #     _item.min_pressure = item['ZXQY']
  #     _item.max_wind = item['ZXFS']
  #     _item.move_speed = item['YDSD']
  #     _item.move_direction = item['YDFX']
  #     _item.seven_radius = item['RADIUS7']
  #     _item.ten_radius = item['RADIUS10']
  #     last_forecast_time[_item.unit] = _item.report_time
  #     _item.save
  #   end

  #   build_content last_forecast_time

  #   nil
  # end

  def build_content last_forecast_time
    real_path = pri_typhoon_items.where(info: 0).order(cur_time: :asc)
    json_result = {
      name: serial_number,
      cname: cname,
      ename: ename,
      last_report_time: last_report_time.strftime("%F %H:%M"),
      level: real_path.last.max_wind,
      real_location: real_path
    }
    if status == 0
      json_result['status'] = 'stop'
    else
      _forecast_location = pri_typhoon_items.where(info: 1).order(cur_time: :asc).group_by {|item| item.unit}
      forecast_location = {}
      _forecast_location.each do |key, items|
        items.each do |item|
          if item.report_time == last_forecast_time[key]
            forecast_location[key] ||= []
            forecast_location[key] << item
          end
        end
      end

      sh_typhoon = Typhoon.where(name: serial_number, location: 'bcsh').first
      if sh_typhoon.present?
        sh_typhoon_forecast = sh_typhoon.typhoon_items.where.not(effective: 0).last(2)

        forecast_location['上海'] = []
        sh_typhoon_forecast.each do |item|
          if item.effective != 72
            forecast_location['上海'] << {
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
              speed: item.speed
            }
          end
        end
      end
      json_result['forecast_location'] = forecast_location
    end
    $redis.hset "pri_typhoon_cache", serial_number, json_result.to_json
  end

  class PriTyphoonProcess
    include NetworkMiddleware

    def initialize
      @root = self.class.to_s
      super
    end

    def fetch params
      params_hash = {
        method: 'post',
        data: params
      }

      result = get_data(params_hash, {})
    end
  end
end
