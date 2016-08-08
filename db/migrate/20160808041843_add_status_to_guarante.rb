class AddStatusToGuarante < ActiveRecord::Migration
  def change
    add_column :guarantes, :status, :integer
  end
end
