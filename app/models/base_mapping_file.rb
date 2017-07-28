class BaseMappingFile < BaseForecast
 
  Mappings = {
    '10.228.38.2' => '/home/deploy/iws/',
  }

  def initialize
    super
    @mapping_path = Mappings[ @server.to_s ]
  end

  private
    def connect!
      @connection = MappingsDir.new(
        File.join( @mapping_path, @remote_dir, '/' )
      )  # '/' 防止文件与文件夹重名
    end

end