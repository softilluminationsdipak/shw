class AddFlaggedColumnToContractors < ActiveRecord::Migration
  def self.up
    add_column :contractors, :flagged, :boolean, :default => false
  end

  def self.down
  	remove_column :contractors, :flagged
  end
end
