class AddColumnGatewayIdToTransaction < ActiveRecord::Migration
  def change
    add_column :transactions, :gateway_id, :integer
  end
end
