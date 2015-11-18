class CreateHealthWeathers < ActiveRecord::Migration
  def change
    create_table :health_weathers do |t|
      t.string :title
      t.datetime :datetime
      t.integer :level
      t.string :desc
      t.string :info
      t.string :guide

      t.timestamps null: false
    end
    add_index :health_weathers, :datetime
    add_index :health_weathers, :title
  end
end
