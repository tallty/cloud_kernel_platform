class CreateStableStations < ActiveRecord::Migration
  def change
    create_table :stable_stations do |t|
      t.datetime :datetime
      t.string :site_number
      t.string :site_name
      t.float :tempe
      t.float :rain
      t.float :humi
      t.float :air_press
      t.float :wind_direction
      t.float :wind_speed
      t.float :vis

      t.timestamps null: false
    end
    add_index :stable_stations, :datetime
    add_index :stable_stations, :site_number
  end
end
