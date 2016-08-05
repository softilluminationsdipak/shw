class AddVerifiedColumnToAddresses < ActiveRecord::Migration
  def self.up
    add_column :addresses, :verified, :boolean, :default => false
  end

  def self.down
  	remove_column :addresses, :verified
  end
end
