class AddBaiduLocationToWaterBugInfo < ActiveRecord::Migration
  def change
    add_column :water_bug_infos, :baidu_lon, :float
    add_column :water_bug_infos, :baidu_lat, :float
  end
end
