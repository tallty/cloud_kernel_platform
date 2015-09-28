class StableStation < ActiveRecord::Base

  def as_json(options=nil)
    {
      datetime: datetime.strftime("%Y-%m-%d %H:%M"),
      site_name: site_name,
      tempe: tempe,
      rain: rain,
      humi: humi,
      air_press: air_press,
      wind_direction: wind_direction,
      wind_speed: wind_speed,
      vis: vis
    }
  end

  def self.process
    p "#{Time.now}: process stable stations"
    StableStationProcess.new.process    
  end

  class StableStationProcess < BaseLocalFile
    def initialize
      super
      @redis_key = "stable_stations"
      @redis_last_report_time_key = "stable_stations_last_report_time"
      
    end

    def file_format
      ".*.txt"
    end

    def get_report_time_string file_name
      p file_name
      File.ctime(file_name).strftime("%Y-%m-%d %H:%M:%S")
    end

    def parse local_file
      p "process stable station ---> #{local_file}"
      file_content = ""
      File.foreach(local_file, encoding: 'gbk') do |line|
        line = line.encode('utf-8')
        line_content = line.split(' ')
        datetime = Time.parse(line_content[0])
        item = StableStation.find_or_create_by datetime: datetime, site_number: line_content[1]
        item.site_name = line_content[2]
        item.tempe = line_content[3].eql?('////') ? 99999 : line_content[3].to_f
        item.rain = line_content[4].eql?('////') ? 99999 : line_content[4].to_f
        item.humi = line_content[5].eql?('////') ? 99999 : line_content[5].to_f
        item.air_press = line_content[6].eql?('////') ? 99999 : line_content[6].to_f
        item.wind_direction = line_content[7].eql?('////') ? 99999 : line_content[7].to_f
        item.wind_speed = line_content[8].eql?('////') ? 99999 : line_content[8].to_f
        item.vis = line_content[9].eql?('////') ? 99999 : line_content[9].to_f

        item.save
        $redis.hset @redis_key, item.site_number, item.to_json
      end
      
    end
  end
end