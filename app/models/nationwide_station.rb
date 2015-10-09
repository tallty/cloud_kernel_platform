class NationwideStation < ActiveRecord::Base
  establish_connection :old_database
  self.table_name = "cs_groups"
  has_many :nationwide_station_items
end
