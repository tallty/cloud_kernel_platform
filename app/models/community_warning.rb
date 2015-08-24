class CommunityWarning < ActiveRecord::Base
  validates :publish_time, :warning_type, :level, :unit, presence: true

  def process
    CommunityWarningProcess.new.process
    clear_cache
  end

  class CommunityWarningProcess < BaseLocalFile
    def initialize
      super

      @redis_last_report_time_key = "community_warning_last_report_time"
      # $redis.del @redis_last_report_time_key
    end

    def file_format
      ".*.txt"
    end

    def get_report_time_string filename
      report_time_string = filename.split(/\/|\./)[-2]
    end

    def parse local_file
      file_content = ""
      File.foreach(local_file, encoding: 'gbk') do |line|
        line = line.encode('utf-8')
        file_content << line
      end
      contents = /上海中心气象台(.*?)(发布|解除|撤销|更新)(.*)(雷电|暴雨|暴雨内涝|暴雨积涝)(风险)(I|II|III|IV)级预警：(.*)/.match(file_content)

      if contents.present?
        units = contents[3].split('、')
        units.each do |unit|
          datetime = Time.strptime(contents[1],"%Y年%m月%d日%H时%M分").to_time
          p datetime
          warning = CommunityWarning.find_or_create_by(publish_time: datetime, unit: unit, warning_type: contents[4])
          warning.status = contents[2]
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
      publish_time: publish_time.strftime("%Y年%m月%d日%H时%M分"),
      warning_type: warning_type,
      level: level,
      content: content,
      status: status,
      unit: unit
    }
  end

  def clear_cache
    warnings = $redis.hgetall "warning_communities"
    clear_time = Time.now - 3.hours
    warnings.map do |e, item|
      item = MultiJson.load item
      if item["status"].eql?("解除") or item["status"].eql?("撤销")
        if Time.strptime(item["publish_time"],"%Y年%m月%d日%H时%M分").to_time < clear_time
          $redis.hdel(warning_key, e)
        end
      end
      
    end
  end
end
