class TotalInterface

  def initialize
    @push_message_data = []
  end

  def clear
    keys = $redis.keys("total_*")
    now_date = Date.today
    keys.each do |key|
      del_key key
    end
  end

  def del_key(key)
    key_time_str = key.split('_')[-1]
    time = Time.parse(key_time_str)
    $redis.del(key) if time.to_date < now_date
  end

  def process
    keys = $redis.keys("total_*")
    interface_time = nil
    keys.each do |key|
      begin
        interface_time = Time.parse(key.split('_')[-1])
        if interface_time < Time.now - 1.hour
          pattern = /total_(.{20})_(.{8})_\d{10}/.match(key)
          @push_message_data << {"datetime" => interface_time, "appid" => pattern[1], "interface_name" => pattern[2], "interface_count" => $redis.get(key)}
          # $redis.del key
          del_key key
        end
      rescue
        next
      end
    end
  end

  def push_message
    # conn = Faraday.new(:url => 'http://shtzr1984.tunnel.mobi') do |faraday|
    conn = Faraday.new(:url => 'http://139.196.105.29') do |faraday|
      faraday.request  :url_encoded
      faraday.adapter  Faraday.default_adapter
    end

    # 提交任务处理情况
    response = conn.post "http://139.196.105.29/total_interfaces/fetch", {total_interfaces: {identifier: 'v7XGbzhd', data: @push_message_data.to_json } }
    @push_message_data.clear
  end
end
