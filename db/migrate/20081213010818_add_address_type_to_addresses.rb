class AddAddressTypeToAddresses < ActiveRecord::Migration
  def self.up
    add_column :addresses, :address_type, :string, :null => false
  end

  def self.down
  	remove_column :addresses, :address_type
  end
end
