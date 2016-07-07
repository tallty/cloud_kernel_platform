class CreatePriTyphoonItems < ActiveRecord::Migration
  def change
    create_table :pri_typhoon_items do |t|
      t.datetime :report_time
      t.datetime :cur_time
      t.float :lon
      t.float :lat
      t.float :min_pressure
      t.float :max_wind
      t.float :move_speed
      t.float :move_direction
      t.float :seven_radius
      t.float :ten_radius
      t.string :unit
      t.integer :info

      t.references :pri_typhoon, index: true
      
      t.timestamps null: false
    end
  end
end
