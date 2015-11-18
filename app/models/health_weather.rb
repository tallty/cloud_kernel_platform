# == Schema Information
#
# Table name: health_weathers
#
#  id         :integer          not null, primary key
#  title      :string(255)
#  datetime   :datetime
#  level      :integer
#  desc       :string(255)
#  info       :string(255)
#  guide      :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

require 'rexml/document'

class HealthWeather < ActiveRecord::Base

  def process
    puts "#{DateTime.now}: process Health Weather data..."
    HealthWeatherProcess.new.fetch
  end

  def clear_redis
    keys = $redis.keys("health_weather_report*")
    now_date = Time.now.to_date
    key_time = nil
    keys.each do |key|
      key_time = Time.parse(key.split('/')[-1])
      if now_date - 3.day > key_time
        p key
      end
    end
  end

  def as_json(options=nil)
    {
      title: title.to_s,
      datetime: datetime.strftime('%Y-%m-%d'),
      level: level.to_i,
      desc: desc.to_s,
      info: info.to_s,
      guide: guide.to_s
    }
  end

  class HealthWeatherProcess

    def fetch
      url = "http://222.66.83.21:808/ScreenDisplay/HealthWeather2/webservice/Publish.asmx/GetCrows"
      @redis_key = "health_weather_report"
      uri = URI.parse(url)
      req = Net::HTTP::Post.new(uri)
      req.set_form_data({"authCode" => "shjkqxyb"})
      res = Net::HTTP::start(uri.host, uri.port) do |http|
        http.read_timeout = 30
        http.request(req)
      end
      content = res.body
      xmldoc = REXML::Document.new(content)
      root = xmldoc.root.elements[2].elements[1]
      root.elements.each do |e|
        title = e.text('Crow')
        datetime = e.text('Date').to_date
        item = HealthWeather.find_or_create_by title: title, datetime: datetime
        item.level = e.text('WarningLevel')
        item.desc = e.text('WarningDesc')
        item.info = e.text('Influ')
        item.guide = e.text('Wat_guide')
        item.save
        $redis.hset "#{@redis_key}/#{datetime}", title, item.to_json
      end
      root = nil
    end
  end
end
