class MappingsDir < Dir

  def nlst ftpfile_format
    # 转化为ruby正则
    ftpfile_format.gsub!(/\.|\*/, '.'=> '\.', '*'=>'.*' )
    self.select { |filename| 
      filename.match(Regexp.new(ftpfile_format))
    }
  end

  def getbinaryfile filename, local_file
    full_path = self.path + filename
    FileUtils.cp full_path, local_file
  end

  def method_missing(method_name, *args, &block)
    return nil if method_name.to_s.in?(['chdir', 'delete'])
    super
  end

end