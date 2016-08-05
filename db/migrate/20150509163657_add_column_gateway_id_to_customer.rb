class AddColumnGatewayIdToCustomer < ActiveRecord::Migration
  def change
    add_column :customers, :gateway_id, :integer
  end
end
