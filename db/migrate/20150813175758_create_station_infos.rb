class CreateStationInfos < ActiveRecord::Migration
  def change
    create_table :station_infos do |t|
      t.string :name
      t.string :alias_name
      t.string :site_number
      t.string :district
      t.string :address
      t.float :lon
      t.float :lat
      t.float :high
      t.string :province
      t.string :site_type
      t.string :subjection
      t.timestamps null: false
    end
  end
end
