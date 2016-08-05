class AddColumnMerchantAccountIdToState < ActiveRecord::Migration
  def change
    add_column :states, :merchant_account_id, :integer
  end
end
