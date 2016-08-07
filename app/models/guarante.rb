# == Schema Information
#
# Table name: guarantes_2016
#
#  id                :integer          not null, primary key
#  trans_id          :string(255)
#  source            :string(255)
#  policy_no         :string(255)
#  product_no        :string(255)
#  liabilities       :string(255)
#  policy_start_date :datetime
#  policy_end_date   :datetime
#  destination       :string(255)
#  region_code       :string(255)
#  trade_type        :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class Guarante < ActiveRecord::Base
  has_many :guarante_items, dependent: :destroy
  validates_uniqueness_of :trans_id, :message => "trans_id don\'t repeat"
  enum trade_type: ['I', 'S']
  def self.build raw_post
    guarante_hash = MultiJson.load raw_post rescue {}
    Sneakers.logger.info guarante_hash
    item = Guarante.find_or_create_by trans_id: guarante_hash['transID']
    item.source = guarante_hash['source']
    item.policy_no = guarante_hash['policyNo']
    item.product_no = guarante_hash['productNo']
    # item.liabilities = guarante_hash['policyNo']
    item.policy_start_date = DateTime.parse(guarante_hash['policyStartDate'])
    item.policy_end_date = DateTime.parse(guarante_hash['policyEndDate'])
    item.destination = guarante_hash['destination']
    item.region_code = guarante_hash['regionCode']
    item.trade_type = guarante_hash['tradeType']
    item.save
  end

  private
  def self.table_name
    _year = DateTime.now.year
    table_name = "guarantes_#{_year}"
    create_table(table_name)
    table_name
  end

  def self.create_table(my_table_name)
    if table_exists?(my_table_name)
      ActiveRecord::Migration.class_eval do
        create_table my_table_name.to_sym do |t|
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
        add_index my_table_name.to_sym, :trans_id, unique: true
      end
    end
    self
  end

  def self.table_exists?(sign=nil)
    flag = ActiveRecord::Base.connection.tables.include? sign
    return !flag
  end
end
