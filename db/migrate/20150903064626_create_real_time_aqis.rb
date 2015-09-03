class CreateRealTimeAqis < ActiveRecord::Migration
  def change
    create_table :real_time_aqis do |t|
      t.datetime :datetime
      t.integer :aqi
      t.string :level
      t.string :pripoll
      t.string :content
      t.string :measure

      t.timestamps null: false
    end
    add_index :real_time_aqis, :datetime
  end
end
