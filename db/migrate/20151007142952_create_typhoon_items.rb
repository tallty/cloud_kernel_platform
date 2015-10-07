class CreateTyphoonItems < ActiveRecord::Migration
  def change
    create_table :typhoon_items do |t|
      t.string :location
      t.datetime :report_time
      t.integer :effective
      t.float :lon
      t.float :lat
      t.float :max_wind
      t.float :min_pressure
      t.float :seven_radius
      t.float :ten_radius
      t.float :direct
      t.float :speed
      t.references :typhoon, index: true
      
      t.timestamps null: false
    end
    add_index :typhoon_items, :location
    add_index :typhoon_items, :effective
  end
end
