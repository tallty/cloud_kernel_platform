class CreateNationwideStations < ActiveRecord::Migration
  def change
    create_table :nationwide_stations do |t|
      t.datetime :report_date
      
      t.timestamps null: false
    end
    add_index :nationwide_stations, :report_date
  end
end
