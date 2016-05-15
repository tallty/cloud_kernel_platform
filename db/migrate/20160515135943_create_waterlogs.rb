class CreateWaterlogs < ActiveRecord::Migration
  def change
    create_table :waterlogs, :id => false do |t|
      t.datetime :datetime
      t.string :site_name
      t.string :area
      t.float :out_water
      t.float :starsky
      t.float :max
      t.date :max_day

      t.timestamps null: false
    end
    add_index :waterlogs, [:datetime, :site_name], :unique => true
  end
end
