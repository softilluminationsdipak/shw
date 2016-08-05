class AddColumnIsDefaultToMerchantAccount < ActiveRecord::Migration
  def change
    add_column :merchant_accounts, :is_default, :boolean, default: false
  end
end
