class AqiItem
  attr_accessor :period, :aqi_value, :level, :pripoll

  def as_json(options=nil)
    {
      period: period,
      aqi: aqi_value,
      level: level,
      pripoll: pripoll
    }
  end
end
