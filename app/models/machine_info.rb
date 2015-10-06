class MachineInfo

  # cpu, filesystem, kernel, memory, network, ipaddress, 
  # macaddress, ip6address, os, os_version, platform, platform_version, 
  # platform_build, platform_family, uptime_seconds, uptime, virtualization, 
  # languages, chef_packages, gce, cloud, command, filesystem2, dmi, hostname, 
  # fqdn, machinename, keys, ohai_time, etc, current_user, root_group
  def initialize
    @system = Ohai::System.new
  end

  def get_info mod
    @system.all_plugins("#{mod}")
    data = MultiJson.load @system.to_json
  end

  def send_base_info
    info = {}
    cpu_info = self.get_info("cpu")["cpu"]
    info["cpu"] = { "module_name" => cpu_info["0"]["model_name"], "mhz" => cpu_info["0"]["mhz"], "total" => cpu_info["total"], "real" => cpu_info["real"]}
    
    net_work_info = self.get_info("network")["network"]["interfaces"]["em1"]["addresses"]
    info["net_work"] = { "network_address" => net_work_info.keys[1], "external_address" => "" }

    memory_info = self.get_info("memory")["memory"]
    info["memory"] = { "swap_total" => memory_info["swap"]["total"], "total" => memory_info["total"] }
    
    conn = Faraday.new(:url => "http://shtzr1984.tunnel.mobi") do |faraday|
      faraday.request  :url_encoded
      faraday.response :logger
      faraday.adapter  Faraday.default_adapter
    end

    # 提交硬件基础信息
    # cpu型号,cpu核数,内网ip地址,服务器型号,内存信息
    response = conn.post "http://shtzr1984.tunnel.mobi/machines", {machine: { identifier: 'U5Hjp3iKSYnNodvy', info: info } }
    p response.body
  end
end
