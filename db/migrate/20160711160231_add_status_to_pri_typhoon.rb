class AddStatusToPriTyphoon < ActiveRecord::Migration
  def change
    add_column :pri_typhoons, :status, :integer, default: 0
  end
end
