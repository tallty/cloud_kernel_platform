class CreateGuaranteItems < ActiveRecord::Migration
  def change
    create_table :guarante_items do |t|
      t.integer :type
      t.string :data
      t.references :guarante
      t.timestamps null: false
    end
  end
end
