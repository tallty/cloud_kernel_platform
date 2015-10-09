class NationwideStationItem < ActiveRecord::Base
  establish_connection :old_database
  self.table_name = "cs_items"
  set_primary_key 'cs_group_id'
  belongs_to :nationwide_station
end
