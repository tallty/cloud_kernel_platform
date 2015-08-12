class BaseLocalFile
  def initialize
    settings = Settings.__send__ self.class.to_s
    settings.each do | k, v |
      instance_variable_set "@#{k}", v
    end
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

  # 遍历目录
  def process
    file_regexp = Regexp.new file_format
    file_list = []
    Dir.foreach(@resource_folder) do | filename |
      matcher = file_regexp.match(filename)
      if matcher.present?
        begin
          local_file = File.join @resource_folder, filename
          file_ext_name = File.extname(filename)
          file_base_name = File.basename(local_file, file_ext_name)
          new_file = File.join(@resource_folder, file_base_name << '.dat')
          if @is_backup
            FileUtils.makedirs(@backup_folder) unless File.exist? @backup_folder
            FileUtils.cp(local_file, @backup_folder)
          end
          FileUtils.mv local_file, new_file, :force => true
          file_list << new_file  
        rescue Exception => e
          next
        end
      end
    end
    puts "#{file_list.length}"
    file_list.each do | file |
      parse file
      FileUtils.rm(file) if @file_delete
    end
  end

end