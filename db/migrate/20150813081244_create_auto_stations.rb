class CreateAutoStations < ActiveRecord::Migration
  def change
    create_table :auto_stations do |t|
      t.string :datetime
      t.string :sitenumber
      t.string :name
      t.string :tempe
      t.string :rain
      t.string :wind_direction
      t.string :wind_speed
      t.string :visibility
      t.string :humi
      t.string :max_tempe
      t.string :min_tempe
      t.string :max_speed
      t.string :max_direction
      t.string :pressure
      t.timestamps null: false
    end

  end
end
