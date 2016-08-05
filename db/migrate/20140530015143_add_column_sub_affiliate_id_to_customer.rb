class AddColumnSubAffiliateIdToCustomer < ActiveRecord::Migration
  def change
    add_column :customers, :sub_affiliate_id, :integer
  end
end
