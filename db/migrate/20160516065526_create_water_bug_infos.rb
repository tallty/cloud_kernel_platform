class CreateWaterBugInfos < ActiveRecord::Migration
  def change
    create_table :water_bug_infos do |t|
      t.string :name
      t.float :lon
      t.float :lat

      t.timestamps null: false
    end
  end
end
