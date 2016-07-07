class CreatePriTyphoons < ActiveRecord::Migration
  def change
    create_table :pri_typhoons do |t|
      t.string :serial_number
      t.datetime :last_report_time
      t.string :cname
      t.string :ename
      t.integer :year

      t.timestamps null: false
    end
    add_index :pri_typhoons, :serial_number, unique: true
  end
end
