class CreateNationwideStationItems < ActiveRecord::Migration
  def change
    create_table :nationwide_station_items do |t|
      t.datetime :report_date
      t.string :sitenumber
      t.string :city_name
      t.float :tempe
      t.float :rain
      t.float :wind_direction
      t.float :wind_speed
      t.float :visibility
      t.float :pressure
      t.float :humi
      t.references :nationwide_station

      t.timestamps null: false
    end
    add_index :nationwide_station_items, :report_date
    add_index :nationwide_station_items, :sitenumber
  end
end
