# == Schema Information
#
# Table name: weather_reports
#
#  id          :integer          not null, primary key
#  datetime    :datetime
#  promulgator :string(255)
#  report_type :string(255)
#  content     :text(65535)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class WeatherReport < ActiveRecord::Base

  def process
    ShortTimeReportProcess.new.process
  end

  def as_json(options=nil)
    {
      datetime: datetime.strftime("%Y-%m-%d %H:%M"),
      type: report_type,
      content: content
    }
  end

  class ShortTimeReportProcess < BaseForecast
    def initialize
      super
      @remote_dir = @remote_dir.encode('gbk')
      @redis_last_report_time_key = "short_time_report_last_report_time"
    end

    protected
    def get_report_time_string file_name
      report_time_string = file_name.split(/\_|\./)[-2]
    end

    def ftpfile_format day
      "smc_dsyb_#{to_date_string(day)}*.txt"
    end

    def parse file_name
      p "process weather report: #{file_name}"
      file_content = ""
      File.foreach(file_name, encoding: @file_encoding) do |line|
        line = line.encode 'utf-8'
        file_content << line
      end

      datetime = get_report_time_string file_name
      report = WeatherReport.find_or_create_by(datetime: Time.zone.parse(datetime), report_type: "短时预报")
      report.promulgator = "中心台"
      report.content = file_content
      report.save

      $redis.hset("weather_reports", report.report_type, report.to_json)
    end
  end
end
