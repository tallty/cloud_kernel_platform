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
    puts "uw_cputop is #{usw.uw_cputop}"
    puts "uw_memtop is #{usw.uw_memtop}"
    puts "uw_load is #{usw.uw_load}"
    puts "uw_cpuused is #{usw.uw_cpuused}"
    puts "uw_tcpused is #{usw.uw_tcpused}"
    puts "uw_udpused is #{usw.uw_udpused}"
    puts "uw_memused is #{usw.uw_memused}"
    puts "uw_bandrx is #{usw.uw_bandrx}"
    puts "uw_bandtx is #{usw.uw_bandtx}"
    puts "uw_diskioreads is #{usw.uw_diskioreads}"
    puts "uw_diskiowrites is #{usw.uw_diskiowrites}"

    system = Ohai::System.new
    system.all_plugins("network")
    data = MultiJson.load system.to_json    
    puts "rx is #{data["counters"]["network"]["interfaces"]["em1"]["rx"]}"
    puts "tx is #{data["counters"]["network"]["interfaces"]["em1"]["tx"]}"
  end

  def send_base_info
    info = {}

    cpu_info = self.get_info("cpu")["cpu"]
    info["cpu"] = { "name" => cpu_info["0"]["model_name"], "mhz" => cpu_info["0"]["mhz"], "total" => cpu_info["total"], "real" => cpu_info["real"]}
    
    net_work_info = self.get_info("network")
    net_work_interfaces_info = net_work_info["network"]["interfaces"]["em1"]["addresses"]
    info["net_work"] = { "network_address" => net_work_interfaces_info.keys[1], "external_address" => "" }

    memory_info = self.get_info("memory")["memory"]
    info["memory"] = { "swap_total" => memory_info["swap"]["total"], "total" => memory_info["total"] }

    send_info info, "base_hardware_info"
  end

  def send_info info, target
    conn = Faraday.new(:url => @monitor_url) do |faraday|
      faraday.request  :url_encoded
      faraday.adapter  Faraday.default_adapter
    end

    # 提交硬件基础信息
    # cpu型号,cpu核数,内网ip地址,服务器型号,内存信息
    response = conn.post "#{@monitor_url}/machines/#{target}", {machine: { identifier: @identifier, datetime: Time.now.strftime("%Y%m%d%H%M%S"), info: info } }
    # p response.body
  end

  def keep_send_real_time_info
    2.times do |i|
      send_real_time_info
      break if i > 0
      sleep 30
    end
  end

  def send_real_time_info
    usw = Usagewatch
    vmstat = Vmstat.snapshot
    info = {}

    date_time = Time.now.strftime("%Y%m%d%H%M%S")
    # CPU: frequence, top
    cpu_info = self.get_info("cpu")["cpu"]
    cpu_sum = 0
    usw.uw_cputop.each do |element|
      cpu_sum += element.last.to_f
    end
    # "real" => cpu_info["real"],
    info["cpu"] = { "date_time" => date_time, "top" => cpu_sum, "cpu_used" => usw.uw_cpuused }

    # network: rx, tx
    net_work_info = self.get_info("network")
    info["net_work"] = { "date_time" => date_time, "rx" => net_work_info["counters"]["network"]["interfaces"]["em1"]["rx"]["bytes"], "tx" => net_work_info["counters"]["network"]["interfaces"]["em1"]["tx"]["bytes"] }

    # memory: used, load average
    info["load_average"] = { "date_time" => date_time, "load_one_minute" => vmstat.load_average.one_minute, "load_five_minutes" => vmstat.load_average.five_minutes, "load_fifteen_minutes" => vmstat.load_average.fifteen_minutes }
    info["memory"] = { "date_time" => date_time, "memory_total_bytes" => vmstat.memory.total_bytes, "memory_free_bytes" => vmstat.memory.free_bytes, "memory_inactive_bytes" => vmstat.memory.inactive_bytes, "memory_wired_bytes" => vmstat.memory.wired_bytes }

    # file_system: local percentage, external exist?
    # @disk
    # @is_full_list
    file_system = self.get_info("filesystem")
    lost_file_system = @disk - file_system["filesystem"].keys
    
    # info["file_system"] = { file_system["filesystem"].first.first => file_system["filesystem"].first.last["percent_used"] }
    # file_system["filesystem"].delete(file_system["filesystem"].first.first)
    # exist_disks = file_system["filesystem"].keys
    tmp_list = []
    percent_used = ''
    @is_full_list.each do |disk|
      percent_used = file_system["filesystem"][disk]["percent_used"]
      tmp_list << "#{disk}::#{percent_used}"
      percent_used = ''
    end
    info["file_system"] = { "date_time" => date_time, "lost_file_system" => lost_file_system.join('#'), "percent_used" => tmp_list.join("#")}
    # @exist_disks.each do |disk|
    #   info["file_system"][disk] = exist_disks.include? disk unless info["file_system"][disk].present?
    # end

    send_info info, "real_hardware_info"
  end
end
