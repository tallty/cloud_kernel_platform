class TestCommunityWarning

  def self.process
    file_content = ""
    File.foreach("20150916134900.txt", encoding: 'gbk') do |line|
      line = line.encode('utf-8')
      file_content << line
    end
    contents = /上海中心气象台(.*?)(发布|解除|撤销|更新)(.*?)(雷电|暴雨|暴雨内涝|暴雨积涝)?(风险)?(I|II|III|IV)级预警(信号)?：(.*)/.match(file_content)
    p file_content
    p contents
    if contents.present?
      units = contents[3].split('、')
      units.each do |unit|
        datetime = Time.strptime(contents[1],"%Y年%m月%d日%H时%M分").to_time + 8.hour
        warning = CommunityWarning.find_or_create_by(publish_time: datetime, unit: unit, warning_type: contents[4])
        warning.status = contents[2]
        warning.level = contents[6]
        warning.content = contents[7]
        warning.save
        p warning
        $redis.hset("warning_communities", "#{warning.unit}_#{warning.warning_type}", warning.to_json)
      end
    end
  end
end
