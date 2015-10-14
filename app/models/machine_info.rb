class MachineInfo

  # cpu, filesystem, kernel, memory, network, ipaddress, 
  # macaddress, ip6address, os, os_version, platform, platform_version, 
  # platform_build, platform_family, uptime_seconds, uptime, virtualization, 
  # languages, chef_packages, gce, cloud, command, filesystem2, dmi, hostname, 
  # fqdn, machinename, keys, ohai_time, etc, current_user, root_group
  def initialize
    @system = Ohai::System.new
    settings = Settings.__send__ self.class.to_s
    settings.each do |k, v|
      instance_variable_set "@#{k}", v
    end
  end

  def get_info mod
    @system.all_plugins("#{mod}")
    data = MultiJson.load @system.to_json
  end

  def get_real_time_info
    usw = Usagewatch
    puts "uw_diskused is #{usw.uw_diskused}"
    puts "uw_diskused_perc is #{usw.uw_diskused_perc}"
    puts "uw_diskavailable is #{usw.uw_diskavailable}"
    puts "uw_cputop is #{usw.uw_cputop}"
    puts "uw_memtop is #{usw.uw_memtop}"
    puts "uw_load is #{usw.uw_load}"
    puts "uw_cpuused is #{usw.uw_cpuused}"
    puts "uw_memused is #{usw.uw_memused}"
    puts "uw_httpconns is #{usw.uw_httpconns}"
    puts "uw_bandrx is #{usw.uw_bandrx}"
    puts "uw_bandtx is #{usw.uw_bandtx}"

    system = Ohai::System.new
    system.all_plugins("network")
    data = MultiJson.load @system.to_json    
    puts "rx is #{data["counters"]["network"]["interfaces"]["en0"]["rx"]}"
    puts "tx is #{data["counters"]["network"]["interfaces"]["en0"]["tx"]}"



  end

  def send_base_info
    info = {}
    cpu_info = self.get_info("cpu")["cpu"]
    info["cpu"] = { "name" => cpu_info["0"]["model_name"], "mhz" => cpu_info["0"]["mhz"], "total" => cpu_info["total"], "real" => cpu_info["real"]}
    
    net_work_info = self.get_info("network")["network"]["interfaces"]["em1"]["addresses"]
    info["net_work"] = { "network_address" => net_work_info.keys[1], "external_address" => "" }

    memory_info = self.get_info("memory")["memory"]
    info["memory"] = { "swap_total" => memory_info["swap"]["total"], "total" => memory_info["total"] }
    
    conn = Faraday.new(:url => @monitor_url) do |faraday|
      faraday.request  :url_encoded
      # faraday.response :logger
      faraday.adapter  Faraday.default_adapter
    end

    # 提交硬件基础信息
    # cpu型号,cpu核数,内网ip地址,服务器型号,内存信息
    response = conn.post "#{@monitor_url}/machines", {machine: { identifier: @identifier, info: info } }
    p response.body
  end
end
