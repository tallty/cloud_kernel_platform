# == Schema Information
#
# Table name: waterlogs
#
#  datetime   :datetime
#  site_name  :string(255)
#  area       :string(255)
#  out_water  :float(24)
#  starsky    :float(24)
#  max        :float(24)
#  max_day    :date
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Waterlog < ActiveRecord::Base
  self.primary_keys = :datetime, :site_name
  validates :datetime, uniqueness: { scope: :site_name }
  
  def as_json(options=nil)
    {
      datetime: datetime,
      site_name: site_name,
      out_water: out_water,
      starsky: starsky
    }
  end

  def process
    WaterlogProcess.new.process
  end

  class WaterlogProcess 

    def initialize
      @data_source = Settings.WaterlogProcess.source
      @redis_key = "waterlogs"
      @redis_list_key = "waterlogs_list"
    end

    def process
      contents = get_data
      contents.each do |content|
        datetime = DateTime.parse(content['DATETIME'])
        site_name = content['STATIONNAME']
        item = Waterlog.proxy(year: datetime.year).find_or_create_by(datetime: datetime, site_name: site_name)
        item.area = content['QUYU']
        item.out_water = content['OUTWATER'].to_f
        item.starsky = content['JJSW'].to_f
        item.max = content['ZGSW'].to_f
        item.max_day = Date.parse(content['ZGSWSJ']) rescue nil
        item.save

        $redis.hset @redis_key, item.site_name, item.to_json
        value = $redis.lindex "#{@redis_list_key}/#{item.site_name}", 0
        if value.nil?
          $redis.lpush "#{@redis_list_key}/#{item.site_name}", item.to_json
          next
        end
        value_hash = MultiJson.load(value)
        
        if (item.datetime > DateTime.parse(value_hash['datetime'])) and item.datetime.minute == 0
          $redis.lpush "#{@redis_list_key}/#{item.site_name}", item.to_json
        end
        $redis.ltrim "#{@redis_list_key}/#{item.site_name}", 0, 75
      end
      nil
    end

    def get_data
      conn = Faraday.new(:url => @data_source) do |faraday|
        faraday.request :url_encoded
        faraday.adapter Faraday.default_adapter
      end
      response = conn.get "#{@data_source}/dataservice/JsonService.svc/GetShuiWeiShiShi/1/ALL", {DISTRICT: '因特网'}
      MultiJson.load response.body rescue []
    end
  end

  def self.proxy(params={})
    year = params[:year] || params['year']
    sign = year ? "waterlogs_#{year}" : "waterlogs"
    create_table(sign)
    self.table_name = sign
    self.primary_keys = :datetime, :site_name
    return self
  end

  def self.create_table(my_table_name)
    if table_exists?(my_table_name)
      ActiveRecord::Migration.class_eval do
        create_table my_table_name.to_sym, :id => false do |t|
          t.datetime :datetime
          t.string :site_name
          t.string :area
          t.float :out_water
          t.float :starsky
          t.float :max
          t.date :max_day

          t.timestamps null: false
        end
        add_index my_table_name.to_sym, [:datetime, :site_name], :unique => true
      end
    end
    self
  end

  def self.table_exists?(sign=nil)
    flag = ActiveRecord::Base.connection.tables.include? sign
    return !flag
  end
end
