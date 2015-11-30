# == Schema Information
#
# Table name: community_warnings
#
#  id           :integer          not null, primary key
#  publish_time :datetime
#  warning_type :string(255)
#  level        :string(255)
#  content      :text(65535)
#  unit         :string(255)
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  status       :string(255)
#

require 'test_helper'

class CommunityWarningTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
