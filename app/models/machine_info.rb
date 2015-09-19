class MachineInfo

  def initialize
    p "------------------------------------------------"  
    p "MachineInfo initialize"
    
    system = Ohai::System.new
    system.all_plugins
    @output = MultiJson.load system.to_json
    p @output.keys
    p "------------------------------------------------"  
    get_cpu_info
    get_memory_info
    get_network_info
    get_disk_info
  end

  def get_cpu_info
    p "------------------------------------------------"  
    p "cpu info"
    p "------------------------------------------------"  
    p @output["cpu"]
  end

  def get_memory_info
    p "------------------------------------------------"  
    p "memory info"
    p "------------------------------------------------"  
    p @output["memory"]
  end

  def get_network_info
    p "------------------------------------------------"  
    p "network info"
    # ["interfaces", "default_gateway", "default_interface", "settings"]
    p "------------------------------------------------"  
    p @output["network"]["interfaces"]
  end

  def get_disk_info
    p "------------------------------------------------"  
    p "file system info"
    p "------------------------------------------------"  
    p @output["filesystem"]
  end

end
