class AddCoverageDescriptionToPackages < ActiveRecord::Migration
  def self.up
  	create_table :packages do |t|
  		t.string :package_name
  		t.float :single_price, :default => 0
  		t.float :condo_price, :default => 0
  		t.float :duplex_price
  		t.float :triplex_price
  		t.float :fourplex_price
    end
  end

  def self.down
  	drop_table :packages
  end
end
