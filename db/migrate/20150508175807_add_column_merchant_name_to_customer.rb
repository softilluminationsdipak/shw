class AddColumnMerchantNameToCustomer < ActiveRecord::Migration
  def change
    add_column :customers, :merchant_name, :string
  end
end
