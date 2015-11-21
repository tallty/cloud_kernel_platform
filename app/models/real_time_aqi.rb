# == Schema Information
#
# Table name: real_time_aqis
#
#  id         :integer          not null, primary key
#  datetime   :datetime
#  aqi        :integer
#  level      :string(255)
#  pripoll    :string(255)
#  content    :string(255)
#  measure    :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class RealTimeAqi < ActiveRecord::Base
  # 上海空气质量实况
  
  def self.process
    RealTimeAqiProcess.new.process
  end

  def as_json(options=nil)
    {
      datetime: datetime.strftime("%Y年%m月%d日 %H时"),
      aqi: aqi,
      level: level,
      pripoll: pripoll,
      content: content,
      measure: measure
    }
  end

  class RealTimeAqiProcess
    WEB_SITE = "http://www.semc.com.cn/home/index.aspx"
    
    def process
      @redis_key = "real_time_aqi_report"
      content = get_resource_html
      
      result = analysis content
      
      time_str = result[1].gsub(/[[:blank:]]/, '')
      
      date_time = Time.strptime(time_str, "%Y年%m月%d日%H时").to_time
      item = RealTimeAqi.find_or_create_by datetime: date_time + 8.hour
      item.aqi = result[3].to_i
      item.level = result[4]
      item.pripoll = result[5]
      item.content = result[6]
      item.measure = result[7]
      item.save

      write_to_redis item
    end

    def write_to_redis item
      value = $redis.lrange @redis_key, 0, 0
      unless value[0].as_json == item.to_json
        $redis.lpush @redis_key, item.to_json
      end

      $redis.ltrim @redis_key, 0, 71
    end

    def analysis content
      result = /实时空气质量状况(.*)实时空气质量指数：(.*?)(\d{2,3})(.*)首要污染物(.*?)对健康影响(.*)(建议措施.*)(过去|最近)24小时/.match(content)
    end

    def get_resource_html
      conn = Faraday.new(:url => "http://www.semc.com.cn") do |faraday|
        faraday.request  :url_encoded
        faraday.response :logger
        faraday.adapter  Faraday.default_adapter
      end

      response = conn.get WEB_SITE
      encoding = response.body.scan(/<meta.+?charset=["'\s]*([\w-]+)/i)[0]
      encoding = encoding ? encoding[0].upcase : 'GB18030'
      html = 'UTF-8'==encoding ? response.body : response.body.force_encoding('GB2312'==encoding || 'GBK'==encoding ? 'UTF-8' : encoding).encode('UTF-8')
      doc = Nokogiri::HTML(response.body)
      contents = doc.search('table')
      return contents[0].content.split.join('').to_s
    end
  end
end
