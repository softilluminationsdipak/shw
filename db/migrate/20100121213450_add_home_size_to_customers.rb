class AddHomeSizeToCustomers < ActiveRecord::Migration
  def self.up
    add_column :customers, :home_size_code, :integer
    add_column :customers, :home_occupancy_code, :integer
  end

  def self.down
    remove_column :customers, :home_size_code
    remove_column :customers, :home_occupancy_code
  end
end
