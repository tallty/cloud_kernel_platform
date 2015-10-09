class NationwideStationItem < ActiveRecord::Base
  establish_connection :old_database
  self.table_name = "cs_items"
  belongs_to :nationwide_station
end
