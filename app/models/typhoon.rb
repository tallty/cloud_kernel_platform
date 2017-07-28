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
      reportcenter: location,
      tyear: year.to_s,
      lastreporttime: (last_report_time - 8.hour).strftime('%Y-%m-%d %H:%M:%S')
    }
  end

  def self.process(folder=nil)
    puts "#{DateTime.now}: do Typhoon process..."
    TyphoonProcess.new.process
    
    # folder = "../typhoon"
    
    # get_file_list folder
    nil
  end

  def self.redo folder
    
    get_file_list folder
  end


  def self.analyzed_file typhoon_file
    file_name = File.basename typhoon_file, '.dat'
    file_name_contents = file_name.split('_')
    
    location = file_name_contents[0]
    typhoon_id = file_name_contents[-1]
    
    p file_name_contents
    return if file_name_contents.size != 2 or typhoon_id.size != 4 or typhoon_id.to_i.to_s.rjust(4, '0') != typhoon_id
    typhoon = Typhoon.find_or_create_by name: typhoon_id, location: location
    
    File.foreach(typhoon_file, encoding: 'gbk') do |line|
      line = line.encode 'utf-8'
      line = line.strip
      line_contents = line.split(' ')
      _type = line_type line_contents.size
      
      if _type == :typhoon_title
        _matcher = /(\(+)(.*?)(\)+)/.match(line_contents[-1])
        return if _matcher.blank?
        typhoon.cname = _matcher[2]
      elsif _type == :typhoon_info
        _matcher = /(.*?)\(+/.match(line_contents[0])
        typhoon.ename = _matcher[1]
        typhoon.year = "20#{line_contents[1][0,2]}"
        typhoon.save
      elsif _type == :typhoon_content
        report_time = Time.zone.parse("20#{line_contents[0, 3].join('-')} #{line_contents[3]}")
        p line_contents
        if line_contents[4].to_i == 0
          p "最新预报时间: #{report_time.strftime("%F %H:%M")}"
          typhoon.last_report_time = report_time
          typhoon.save
        end
        now_item_time = report_time + line_contents[4].to_i.hour
        p "点位时间: #{now_item_time}"
        typhoon_item = typhoon.typhoon_items.find_or_create_by report_time: now_item_time, effective: line_contents[4], location: typhoon.location
        typhoon_item.lon          = line_contents[5].to_f
        typhoon_item.lat          = line_contents[6].to_f
        typhoon_item.max_wind     = line_contents[7].to_f
        typhoon_item.min_pressure = line_contents[8].to_f
        typhoon_item.seven_radius = line_contents[9].to_f
        typhoon_item.ten_radius   = line_contents[10].to_f
        typhoon_item.direct       = line_contents[11].to_f
        typhoon_item.speed        = line_contents[12].to_f
        typhoon_item.save
      else
        return
      end
          
    end
    nil
  end

  def self.line_type line_contents
    _type = :unuse
    if line_contents == 3
      _type = :typhoon_title
    elsif line_contents == 4
      _type = :typhoon_info
    elsif line_contents == 13
      _type = :typhoon_content
    else
      _type = :unuse
    end
    _type
  end

  def self.get_file_list f
    Dir.entries(f).each do |sub|         
      if sub != '.' && sub != '..'  
        if File.directory?("#{f}/#{sub}")  
          get_file_list("#{f}/#{sub}")
        else
          analyzed_file "#{f}/#{sub}"
        end  
      end  
    end
  end

  def write_typhoon_to_cache
    show_year = Time.now.year - 2
    typhoons_name = Typhoon.where('year > ?', show_year).order(name: :desc).distinct(:name).pluck(:name)
    typhoons_name.each do |name|
      typhoon = Typhoon.where(name: name).first
      $redis.hset "typhoon_list_json", typhoon.name, typhoon.to_json_hash.to_json
      $redis.hset "typhoon_json_cache", typhoon.name, typhoon.relate_typhoon_items.to_json
    end
    typhoons_name.clear
  end

  def relate_typhoon_items
    items = []
    items.concat self.typhoon_items.where effective: 0
    items.concat self.typhoon_items.where.not(effective: 0).last(3)
    items
  end

  class TyphoonProcess < BaseMappingFile
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

    def get_report_time_string_from_ftp filename
      Time.zone.now.to_s
    end

    def ftpfile_format day
      "*.dat"
    end

    def parse local_file
      p "typhoon file: #{local_file}"
      file_name = File.basename local_file, '.dat'
      file_name_contents = file_name.split('_')

      location = file_name_contents[0]
      typhoon_id = file_name_contents[-1]
      return if file_name_contents.size != 2 or typhoon_id.size != 4 or typhoon_id.to_i.to_s.rjust(4, '0') != typhoon_id
      typhoon = Typhoon.find_or_create_by name: typhoon_id, location: location
      File.foreach(local_file, encoding: @file_encoding) do |line|
        line = line.encode 'utf-8'
        line = line.strip
        line_contents = line.split(' ')
        _type = line_type line_contents.size

        if _type == :typhoon_title
          _matcher = /(\(+)(.*?)(\)+)/.match(line_contents[-1])
          return if _matcher.blank?
          typhoon.cname = _matcher[2]
        elsif _type == :typhoon_info
          _matcher = /(.*?)\(+/.match(line_contents[0])
          typhoon.ename = _matcher[1]
          typhoon.year = "20#{line_contents[1][0,2]}"
          typhoon.save
        elsif _type == :typhoon_content
          report_time = Time.zone.parse("20#{line_contents[0, 3].join('-')} #{line_contents[3]}")
          # report_time = ("20#{line_contents[0, 3].join('-')} #{line_contents[3]}").to_datetime
          if line_contents[4].to_i == 0
            typhoon.last_report_time = report_time
            typhoon.save
          end
          now_item_time = report_time + line_contents[4].to_i.hour
          typhoon_item = typhoon.typhoon_items.find_or_create_by report_time: now_item_time, effective: line_contents[4], location: typhoon.location
          typhoon_item.lon          = line_contents[5].to_f
          typhoon_item.lat          = line_contents[6].to_f
          typhoon_item.max_wind     = line_contents[7].to_f
          typhoon_item.min_pressure = line_contents[8].to_f
          typhoon_item.seven_radius = line_contents[9].to_f
          typhoon_item.ten_radius   = line_contents[10].to_f
          typhoon_item.direct       = line_contents[11].to_f
          typhoon_item.speed        = line_contents[12].to_f
          typhoon_item.save
        else
          next
        end
            
      end
      
      FileUtils.mv(local_file, '/home/deploy/ftp/weathers/typhoon/')

      if @is_process
        
        cache_reload
        # typhoon.last_report_time = last_report_time if typhoon.last_report_time.blank? || last_report_time > typhoon.last_report_time
        # typhoon.ename = ename
        # typhoon.cname = cname
        # typhoon.year  = typhoon.last_report_time.try(:year)
        # typhoon.save

        # $redis.hset "typhoon_json_cache", typhoon.name, typhoon.relate_typhoon_items.to_json
        # $redis.hset "#{@redis_key}_#{typhoon.name}", typhoon.location, typhoon.to_s
        # now_year     = Time.zone.now.year
        # typhoon_list = Typhoon.where(year: [now_year-1, now_year], location: "BCSH").order('last_report_time desc')
        # $redis.set "typhoon_list", typhoon_list.map { |t| t.to_json_hash }.to_json
      end
    end

    def line_type line_contents
      _type = :unuse
      if line_contents == 3
        _type = :typhoon_title
      elsif line_contents == 4
        _type = :typhoon_info
      elsif line_contents == 13
        _type = :typhoon_content
      else
        _type = :unuse
      end
      _type
    end

    def after_process
      
    end
  end
end
