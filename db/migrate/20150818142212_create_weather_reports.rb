class CreateWeatherReports < ActiveRecord::Migration
  def change
    create_table :weather_reports do |t|
      t.datetime :datetime
      t.string :promulgator
      t.string :report_type
      t.text :content

      t.timestamps null: false
    end
    add_index :weather_reports, :datetime
    add_index :weather_reports, :report_type
  end
end
