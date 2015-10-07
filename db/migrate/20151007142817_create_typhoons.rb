class CreateTyphoons < ActiveRecord::Migration
  def change
    create_table :typhoons do |t|
      t.string :name
      t.string :location
      t.string :cname
      t.string :ename
      t.string :data_info
      t.datetime :last_report_time
      t.integer :year

      t.timestamps null: false
    end
    add_index :typhoons, :name
    add_index :typhoons, :location
  end
end
