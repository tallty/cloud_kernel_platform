json.array!(@station_infos) do |station_info|
  json.extract! station_info, :id
  json.url station_info_url(station_info, format: :json)
end
