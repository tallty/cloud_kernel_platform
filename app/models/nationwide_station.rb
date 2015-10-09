class NationwideStation < ActiveRecord::Base
  establish_connection :old_database
  self.table_name = "cs_groups"
  set_primary_key 'cs_group_id'
  has_many :nationwide_station_items
end
