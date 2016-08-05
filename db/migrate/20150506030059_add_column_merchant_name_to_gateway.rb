class AddColumnMerchantNameToGateway < ActiveRecord::Migration
  def change
    add_column :gateways, :merchant_name, :string
  end
end
