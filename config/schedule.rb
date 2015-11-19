# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

set :output, "./log/cron_log.log"
set :job_template, "/usr/bin/timeout 1800 /bin/bash -l -c ':job'"

# Learn more: http://github.com/javan/whenever

every 5.minutes do
  runner "TestTimeOut.new.process"
end

every 1.minutes do
  runner 'MachineInfo.new.keep_send_real_time_info'
end

every 1.minutes do
  runner "StableStation.process"
end

every 1.minutes do
  runner "CommunityWarning.new.process"
end

every 1.minutes do
  runner "GridLive.process"
end

every 2.minutes do
  runner "QPF.new.process"
end

every 5.minutes do
  runner "RealTimeAqi.process"
end

every 5.minutes do
  runner "AqiForecast.process"
end

every 5.minutes do
  runner "WorldForecast.new.process"
end

every 5.minutes do
  runner "Typhoon.process"
end

every 10.minutes do
  runner "ExchangeFile.process"
end

every 10.minutes do
  runner "WeatherReport.new.process"
end

every 20.minutes do
  runner "NationwideStation.process"
end

every 1.hours do
  runner "HealthWeather.new.process"
end

every 1.hours, :at => 30 do
  runner "CountryRealAqi.process"
end

every 1.hours, :at => 25 do
  runner "AutoStation::DataProcess.new.hour_process"
end

every 1.day, :at => "21:30" do
  runner "AutoStation::DataProcess.new.day_process"
end
