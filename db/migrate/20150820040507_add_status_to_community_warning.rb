class AddStatusToCommunityWarning < ActiveRecord::Migration
  def change
    add_column :community_warnings, :status, :string
  end
end
