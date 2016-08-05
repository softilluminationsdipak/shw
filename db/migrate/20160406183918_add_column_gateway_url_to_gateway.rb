class AddColumnGatewayUrlToGateway < ActiveRecord::Migration
  def change
    add_column :gateways, :gateway_url, :string
  end
end
