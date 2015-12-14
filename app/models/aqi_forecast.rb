class AqiForecast
  attr_accessor :datetime, :prompt, :items

  def as_json(options=nil)
    {
      datetime: datetime,
      prompt: prompt,
      list: items.as_json
    }
  end

  def self.process
    p "#{Time.now}: process aqi forecast task..."
    AqiForecastProcess.new.process
  end

  class AqiForecastProcess < BaseForecast
    def initialize()
      super

      @redis_key = "aqi_forecast"
      @redis_last_report_time_key = "aqi_forecast_last_report_time"
    end

    protected

    def get_report_time_string filename
      report_time_string = filename.split(/_|\./)[-2]
    end

    def ftpfile_format day
      "AQI_SH*#{to_date_string(day)}*.txt"
    end

    def parse local_file
      report_time_string = local_file.split(/_|\./)[-2]
      aqi = AqiForecast.new
      aqi.datetime = Time.parse(report_time_string).strftime("%Y年%m月%d日 17时")
      aqi.prompt = ""

      items = []
      File.foreach(local_file, encoding: @file_encoding) do |line|
        line = line.encode 'utf-8'
        line = line.strip
        contents = line.split(" ")
        next if contents.blank?

        if line =~ /今天夜间/ || line =~ /明天上午/ || line =~ /明天下午/
          item = AqiItem.new
          item.period = contents[0]
          item.aqi_value = contents[1]
          item.level = contents[2]
          item.pripoll = contents[3]
          items << item
        end

      end
      aqi.items = items
      $redis.set "#{@redis_key}", aqi.to_json
      items.clear
    end

    def after_process
      @process_result_info["end_time"] = DateTime.now.to_f
      push_task_log @process_result_info.to_json
    end
  end
end
