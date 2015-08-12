class CommunityWarning < ActiveRecord::Base
  validates :publish_time, :warning_type, :level, :unit, presence: true

  def process
    settings = Settings.__send__ "CommunityWarning"
    CommunityWarning.process_dir(settings.resource_folder)
    # clear_cache
  end

  # 遍历目录
  def self.process_dir(dir_path)
    if File.directory?(dir_path)
      Dir.foreach(dir_path) do |filename|
        if filename != "." and filename != ".."
          process_dir(dir_path + "/" + filename)
        end
      end
    else
      CommunityWarning.analy_file dir_path
    end
  end

  def self.analy_file file
    p file
    file_content = ""
    File.foreach(file, encoding: 'gbk') do |line|
      line = line.encode('utf-8')
      file_content << line
    end
    contents = /上海中心气象台(.*?)(发布|解除|撤销|更新)(.*)(雷电|暴雨|暴雨内涝|暴雨积涝)(风险)(I|II|III|IV)级预警：(.*)/.match(file_content)
    p contents
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
