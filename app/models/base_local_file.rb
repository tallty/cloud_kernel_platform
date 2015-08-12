class BaseLocalFile
  def initialize
    settings = Settings.__send__ self.class.to_s
    settings.each do | k, v |
      instance_variable_set "@#{k}", v
    end
    @file_list = []
  end

  ##########################################################
  # should be overwriten
  ##########################################################

  def file_format
    puts "ftpfile_format method should be implement correctly"
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
        @file_list << file
      end
    end
  end

  # 遍历目录
  def process
    self.traverse_folder @resource_folder
    @file_list.each do |item|
      begin
        if @is_backup
          backup_file = item.gsub(@resource_folder, @backup_folder)
          backup_dir = File.dirname(backup_file)
          FileUtils.makedirs(backup_dir) unless File.exist? backup_dir
          FileUtils.cp("#{item}", backup_dir)
        end
        parse item
        FileUtils.rm(item) if @file_delete
      rescue Exception => e
        logger.error "e"
        next
      end
    end
    nil
  end

end
