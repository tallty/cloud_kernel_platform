class CreateCommunityWarnings < ActiveRecord::Migration
  def change
    create_table :community_warnings do |t|
      t.datetime :publish_time
      t.string :warning_type
      t.string :level
      t.text :content
      t.string :unit

      t.timestamps null: false
    end
    add_index :community_warnings, :publish_time
    add_index :community_warnings, :unit
    add_index :community_warnings, :warning_type
  end
end
