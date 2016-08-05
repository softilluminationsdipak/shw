class AddColumnIsDefaultToGateway < ActiveRecord::Migration
  def change
    add_column :gateways, :is_default, :boolean, :default => false
  end
end
