# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
set :output, "./log/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

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

every 10.minutes do
  runner "ExchangeFile.new.process"
end

every 10.minutes do
  runner "WeatherReport.new.process"
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
