class CommunityWarning < ActiveRecord::Base
  validates :publish_time, :warning_type, :level, :unit, presence: true

  def process
    CommunityWarningProcess.new.process
    clear_cache
  end

  class CommunityWarningProcess < BaseLocalFile
    def initialize
      super
    end

    def file_format

    end

    def parse local_file
      file_content = ""
      File.foreach(file, encoding: 'gbk') do |line|
        line = line.encode('utf-8')
        file_content << line
      end
      contents = /上海中心气象台(.*?)(发布|解除|撤销|更新)(.*)(雷电|暴雨|暴雨内涝|暴雨积涝)(风险)(I|II|III|IV)级预警：(.*)/.match(file_content)
      if contents.present?
        units = contents[3].split('、')
        units.each do |unit|
          warning = CommunityWarning.find_or_create_by(publish_time: contents[1], unit: unit, warning_type: contents[4])
          warning.level = contents[6]
          warning.content = contents[7]
          warning.save

          $redis.hset("warning_communities", "#{warning.unit}_#{warning.warning_type}", warning.to_json)
        end
      end
    end
  end

  def as_json options=nil
    {
      publish_time: publish_time,
      warning_type: warning_type,
      level: level,
      content: content,
      unit: unit
    }
  end

  def clear_cache
    warning_key = $redis.keys "warning_communities"
    clear_time = Time.zone.now - 3.hours
    warning_key.each do |key|
      $redis.hgetall(key).map do |e, item|
        item = MultiJson.load item
        if item["level"].eql?("解除") or item["level"].eql?("撤销")
          if Time.zone.parse(item["publish_time"]) < clear_time
            $redis.hdel(warning_key, e)
          end
        end
      end

    end
  end
end
