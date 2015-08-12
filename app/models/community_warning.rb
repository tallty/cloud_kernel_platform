class CommunityWarning < ActiveRecord::Base
  validates :publish_time, :warning_type, :level, :unit, presence: true
end
