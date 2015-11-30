require 'net/ftp'

class BaseTask

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

  def send_file_by_ftp file_name
    connect! unless @connection
    @connection.chdir @remote_dir
    @connection.putbinaryfile(file_name)
    close!
  end
end
