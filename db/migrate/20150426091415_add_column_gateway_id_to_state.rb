class AddColumnGatewayIdToState < ActiveRecord::Migration
  def change
    add_column :states, :gateway_id, :integer
  end
end
