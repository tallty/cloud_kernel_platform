# == Schema Information
#
# Table name: typhoons
#
#  id               :integer          not null, primary key
#  name             :string(255)
#  location         :string(255)
#  cname            :string(255)
#  ename            :string(255)
#  data_info        :string(255)
#  last_report_time :datetime
#  year             :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class Typhoon < ActiveRecord::Base
  has_many :typhoon_items

  def as_json(options=nil)
    {
      name: name,
      unit: location,
      items: relate_typhoon_items.map(&:to_s).join("\n")
    }
  end

  def to_s
    relate_typhoon_items.map(&:to_s).join("\n")
  end

  def to_json_hash
    {
      typhoonid: name,
      enname: ename,
      cnname: cname,
      datainfo: "",
      reportcenter: location,
      tyear: year.to_s,
      lastreporttime: last_report_time.strftime('%Y/%m/%d %H:%M:%S')
    }
  end

  def self.process
    puts "#{DateTime.now}: do Typhoon process..."
    TyphoonProcess.new.process
  end

  def write_typhoon_to_cache
    show_year = Time.now.year - 2
    typhoons_name = Typhoon.where('year > ?', show_year).distinct(:name).pluck(:name)
    typhoons_name.each do |name|
      typhoon = Typhoon.where(name: name).first
      $redis.hset "typhoon_list_json", typhoon.name, typhoon.to_json_hash.to_json
    end
    typhoons_name.clear
  end

  def relate_typhoon_items
    items = []
    items.concat self.typhoon_items.where effective: 0
    items.concat self.typhoon_items.where.not(effective: 0).last(3)
    items
  end

  class TyphoonProcess < BaseForecast
    def initialize
      super
      @redis_key = "typhoon"
      @redis_last_report_time_key = "typhoo_last_report_time"
      @remote_dir = @remote_dir.encode('gbk')
    end

    def cache_reload
      now_year = Time.zone.now.year
      typhoon_list = Typhoon.where(year: [now_year-1, now_year]).order('last_report_time desc')
      typhoon_list.each do |typhoo|
        $redis.hset "#{@redis_key}_#{typhoo.name}", typhoo.location, typhoo.to_s
      end
      typhoon_list = Typhoon.where(year: [now_year-1, now_year], location: "BCSH").order('last_report_time desc')
      $redis.set "typhoon_list", typhoon_list.map { |t| t.to_json_hash }.to_json
    end 

    protected

    def get_report_time_string filename
      Time.zone.now.to_s
    end

    def ftpfile_format day
      "*.dat"
    end

    def parse local_file
      filename         = File.basename local_file
      @is_process      = false
      
      cname            = ""
      ename            = ""
      last_report_time = nil
      index            = 0
      typhoon          = nil

      File.foreach(local_file, encoding: @file_encoding) do |line|
        line     = line.encode 'utf-8'
        line     = line.strip
        contents = line.split(" ")
        if index == 0
          cname = contents[2].split(/\(|\)/)[1]
        elsif index == 1
          name     = contents[1]
          location = contents[2]
          typhoon  = Typhoon.find_or_create_by name: name, location: location
          ename    = contents[0].split(/\(|\)/)[0]
        else
          year             = 2000 + contents[0].to_i
          month            =  contents[1].to_i
          day              = contents[2].to_i
          hour             = contents[3].to_i
          report_time      = Time.zone.local(year, month, day, hour, 0, 0).to_datetime
          last_report_time = report_time
          effective        = contents[4]
          typhoon_item     = typhoon.typhoon_items.find_by(report_time: report_time, effective: effective)
          if typhoon_item.blank?
            @is_process = true
            typhoon_item = typhoon.typhoon_items.build(report_time: report_time, effective: effective)
            typhoon_item.lon          = contents[5].to_f
            typhoon_item.lat          = contents[6].to_f
            typhoon_item.max_wind     = contents[7].to_f
            typhoon_item.min_pressure = contents[8].to_f
            typhoon_item.seven_radius = contents[9].to_f
            typhoon_item.ten_radius   = contents[10].to_f
            typhoon_item.direct       = contents[11].to_f
            typhoon_item.speed        = contents[12].to_f
            typhoon_item.save
          end
          
        end
        index += 1
      end
      
      FileUtils.mv(local_file, '/home/deploy/ftp/weathers/typhoon/')

      if @is_process

        typhoon.last_report_time = last_report_time if typhoon.last_report_time.blank? || last_report_time > typhoon.last_report_time
        typhoon.ename = ename
        typhoon.cname = cname
        typhoon.year  = typhoon.last_report_time.try(:year)
        typhoon.save

        $redis.hset "#{@redis_key}_#{typhoon.name}", typhoon.location, typhoon.to_s
        now_year     = Time.zone.now.year
        typhoon_list = Typhoon.where(year: [now_year-1, now_year], location: "BCSH").order('last_report_time desc')
        $redis.set "typhoon_list", typhoon_list.map { |t| t.to_json_hash }.to_json
      end
    end

    def after_process
      
    end
  end
end
