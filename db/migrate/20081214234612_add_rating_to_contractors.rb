class AddRatingToContractors < ActiveRecord::Migration
  def self.up
    add_column :contractors, :rating, :integer, :default => 3
  end

  def self.down
  	remove_column :contractors, :rating
  end
end
