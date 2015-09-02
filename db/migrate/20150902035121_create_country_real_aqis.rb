class CreateCountryRealAqis < ActiveRecord::Migration
  def change
    create_table :country_real_aqis do |t|
      t.datetime :datetime
      t.string :area
      t.string :position_name
      t.string :station_code
      t.string :primary_pollutant
      t.string :quality
      t.float :aqi
      t.float :co
      t.float :co_24h
      t.float :no2
      t.float :no2_24h
      t.float :o3
      t.float :o3_24h
      t.float :o3_8h
      t.float :o3_8h_24h
      t.float :pm10
      t.float :pm10_24h
      t.float :pm2_5
      t.float :pm2_5_24h
      t.float :so2
      t.float :so2_24h

      t.timestamps null: false
    end
    add_index :country_real_aqis, :datetime
    add_index :country_real_aqis, :position_name
  end
end
