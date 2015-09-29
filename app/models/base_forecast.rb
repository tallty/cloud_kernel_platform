require 'net/ftp'

class BaseForecast

  def initialize
    settings = Settings.__send__ self.class.to_s
    settings.each do |k, v|
      instance_variable_set "@#{k}", v
    end
  end

  def connect!
    @connection = Net::FTP.new
    @connection.connect(@server, @port)
    @connection.passive = @passive || false
    @connection.login(@user, @password)
  end

  def close!
    @connection.close if @connection
    @connection = nil
  end

  ##########################################################
  # should be overwriten
  ##########################################################
  def get_report_time_string filename
    puts "get_report_time_string method should be implement correctly"
  end

  def ftpfile_format day
    puts "ftpfile_format method should be implement correctly"
  end

  def parse local_file
    puts "parse local_file methold should be implement correctly"
  end
  ###########################################################

  def get_report_time_string_from_ftp filename
    @connection.mtime(filename).strftime("%Y-%m-%d %H:%M:%S")
  end

  def to_date_string datetime
    date_string = datetime.strftime('%Y%m%d')
  end

  def to_datetime_string report_time
    report_time.strftime('%Y%m%d%H')
  end

  def process
    today = Time.now.to_date
    today_string = to_date_string today
    day_to_fetch = @day_to_fetch || 1
    last_day_string = to_date_string(today - day_to_fetch)
    time_string = $redis.get(@redis_last_report_time_key)
    p "last_day_string: #{last_day_string}"
    p "time_string: #{time_string}"
    @last_report_time = time_string.blank? ? Time.parse(last_day_string) : Time.parse(time_string) 
    connect! unless @connection
    
    @connection.chdir @remote_dir
    file_infos = []
    file_arr = []
    (0..day_to_fetch).each do |index|
      file_arr.concat @connection.nlst(ftpfile_format(today-index)) rescue []
    end
    file_arr.each do |filename|
      report_time_string = get_report_time_string_from_ftp filename
      filename = filename.encode! 'utf-8', 'gb2312', {:invalid => :replace}
      file_infos << [report_time_string, filename]
    end
    file_infos = file_infos.sort_by { |k, v| k }
    @is_process = false
    close!

    # puts "files is :#{file_infos}"
    file_infos.each do |report_time_string, filename|
      @report_time = Time.parse report_time_string
      @report_time_string = report_time_string
      if @report_time > @last_report_time && @report_time <= Time.now
        @is_process = true
        
        FileUtils.makedirs(@local_dir) unless File.exist?(@local_dir)
        file_local_dir = File.join @local_dir, to_date_string(@report_time)
        FileUtils.makedirs(file_local_dir) unless File.exist?(file_local_dir)
        local_file = File.join file_local_dir, filename
        
        connect! unless @connection
        @connection.chdir @remote_dir
        filename = filename.encode('gbk')
        begin
          Timeout.timeout(20) do
            @connection.getbinaryfile(filename, local_file)  
            @connection.delete(filename) if @file_delete
          end
        rescue
          close!
          next
        end
        close!
        parse local_file

        $redis.set @redis_last_report_time_key, report_time_string
      end
    end
    after_process if respond_to?(:after_process, true)
    # close!
  end

end
