class CreateGuarantes < ActiveRecord::Migration
  def change
    create_table :guarantes do |t|
      t.string :trans_id
      t.string :source
      t.string :policy_no
      t.string :product_no
      t.string :liabilities
      t.datetime :policy_start_date
      t.datetime :policy_end_date
      t.string :destination
      t.string :region_code
      t.integer :trade_type

      t.timestamps null: false
    end
    add_index :guarantes, :trans_id, unique: true
  end
end
