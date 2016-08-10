# == Schema Information
#
# Table name: minute_stations
#
#  datetime    :datetime         not null
#  site_number :string(255)      not null
#  tempe       :float(24)
#  max_tempe   :float(24)
#  min_tempe   :float(24)
#  rain        :float(24)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class MinuteStation < ActiveRecord::Base
  # validates :datetime, uniqueness: { scope: :site_number }
  
  default_scope { order(datetime: :asc) }

  def as_json(options=nil)
    {
      datetime: datetime.strftime('%F %H:%M:%S'),
      tempe: tempe,
      max_tempe: max_tempe,
      min_tempe: min_tempe,
      rain: rain
    }
  end

  def self.process
    StationProcess.new.process  
  end

  class StationProcess < BaseLocalFile
    def initialize
      super
      @redis_last_report_time_key = "one_minute_station_last_report_time"
      @redis_key = "one_minute_stations"
    end

    def file_format
      ".*.txt"
    end

    def get_report_time_string file_name
      File.ctime(file_name).strftime("%Y-%m-%d %H:%M:%S")  
    end

    def parse local_file
      @datetime = nil
      File.foreach(local_file, encoding: 'gbk') do |line|
        line = line.encode('utf-8')
        line = line.strip
        line_contents = line.split(',')
        @datetime = Time.zone.parse(line_contents[0])
        site_number = line_contents[2]
        MinuteStation.find_or_create_by(datetime: @datetime, site_number: site_number)
        MinuteStation.where(datetime: @datetime, site_number: site_number)
        .update_all(
          tempe: line_contents[3],
          max_tempe: line_contents[4],
          min_tempe: line_contents[5],
          rain: line_contents[6]
        )
      end
    end

    def after_process
      items = MinuteStation.where(datetime: @datetime)
      $redis.set @redis_key, items.to_json
    end

  end
end
