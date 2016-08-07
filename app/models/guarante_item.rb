# == Schema Information
#
# Table name: guarante_items
#
#  id          :integer          not null, primary key
#  type        :integer
#  data        :string(255)
#  guarante_id :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class GuaranteItem < ActiveRecord::Base
  belongs_to :guarante
end
