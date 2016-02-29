# == Schema Information
#
# Table name: community_warnings
#
#  id           :integer          not null, primary key
#  publish_time :datetime
#  warning_type :string(255)
#  level        :string(255)
#  content      :text(65535)
#  unit         :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  status       :string(255)
#

class CommunityWarning < ActiveRecord::Base
  validates :publish_time, :warning_type, :level, :unit, presence: true

  def process
    p "#{Time.now}: process community warning task..."
    CommunityWarningProcess.new.process
    clear_cache
  end

  class CommunityWarningProcess < BaseLocalFile
    def initialize
      super
    end

    def file_format
      ".*.txt"
    end

    def get_report_time_string file_name
      File.ctime(file_name).strftime("%Y-%m-%d %H:%M:%S")
    end

    def parse local_file
      File.foreach(local_file, encoding: 'gb2312') do |line|
        line = line.encode('utf-8')
        contents = line.split(':')
        date_time_string = line[3, 12]
        date_time = Time.parse(date_time_string).strftime("%Y-%m-%d %H:%M")
        status = warning_status line[15, 1]
        target = line[16, 5]
        type = line[21, 4]
        _t = warning_types type
        if contents[0].include?('>')
          level = line[27, 1]
          content = line[29, line.size - 28]
        else
          level = line[25, 1]
          content = line[26, line.size - 26]
        end
        warning = CommunityWarning.find_or_create_by(publish_time: date_time, unit: target, warning_type: _t, level: level)
        warning.status = status
        warning.content = content
        warning.save

        $redis.hset("warning_communities", "#{warning.unit}_#{warning.warning_type}", warning.to_json)
      end
    end

    def warning_types code
      case code
      when 'aaaa'
        '雷电'
      when 'bbbb'
        '暴雨内涝'
      end
    end

    def warning_status code
      case code
      when 'g'
        '更新'
      when 'f'
        '发布'
      when 'j'
        '解除'
      end
    end

    def after_process
      @process_result_info["end_time"] = DateTime.now.to_f
      push_task_log @process_result_info.to_json
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
          $redis.hdel("warning_community", e)
        end
      end

    end
  end
end
