class BaseLocalFile
  def initialize
    settings = Settings.__send__ self.class.to_s
    settings.each do | k, v |
      instance_variable_set "@#{k}", v
    end
    @file_list = []
    @process_result_info = {}
  end

  ##########################################################
  # should be overwriten
  ##########################################################

  def file_format
    puts "ftpfile_format method should be implement correctly"
  end

  def get_report_time_string filename
    puts "get_report_time_string method should be implement correctly"  
  end

  def parse local_file
    puts "parse local_file methold should be implement correctly"
  end

  ###########################################################

  def traverse_folder file
    if File.directory?(file)
      Dir.foreach(file) do |item|
        if item != "." and item != ".."
          self.traverse_folder File.join(file, item)
        end
      end
    else
      file_regexp = Regexp.new file_format
      matcher = file_regexp.match file
      if matcher.present?
        report_time_string = Time.parse(get_report_time_string file)
        if report_time_string > @last_report_time
          @file_list << [report_time_string, file]
        end
      end
    end
  end

  def to_date_string datetime
    date_string = datetime.strftime('%Y%m%d')
  end

  # 遍历目录
  def process
    
    @process_result_info["start_time"] = DateTime.now.strftime('%Y%m%d%H%M%S')
    
    time_string = $redis.get(@redis_last_report_time_key)
    today = Time.now.to_date
    day_to_fetch = @day_to_fetch || 1
    last_day_string = to_date_string(today - day_to_fetch)

    @last_report_time = time_string.blank? ? Time.parse(last_day_string) : Time.parse(time_string) 
    self.traverse_folder @resource_folder

    exception = {}
    @file_list.each do |report_time_string, file|
      begin
        if @is_backup
          backup_file = file.gsub(@resource_folder, @backup_folder)
          backup_dir = File.dirname(backup_file)
          FileUtils.makedirs(backup_dir) unless File.exist? backup_dir
          FileUtils.cp("#{file}", backup_dir)
        end
        parse file
        FileUtils.rm(file) if @file_delete
        $redis.set @redis_last_report_time_key, report_time_string
      rescue Exception => e
        exception[filename] = e
        next
      end
    end
    @process_result_info["exception"] = exception.to_json
    @process_result_info["end_time"] = DateTime.now.strftime('%Y%m%d%H%M%S')
    
    after_process if respond_to?(:after_process, true)
  end

  def push_task_log info
    conn = Faraday.new(:url => 'http://shtzr1984.tunnel.mobi') do |faraday|
      faraday.request  :url_encoded
      faraday.adapter  Faraday.default_adapter
    end

    # 提交任务处理情况
    response = conn.post "http://shtzr1984.tunnel.mobi/task_logs/fetch", {task_log: { identifier: 'c45Qx2rEXZORwk8W', process_result: @process_result_info } }
  end

end
