class RemovePackageCovers < ActiveRecord::Migration
  def self.up
    #remove_column :packages, :covers
  end

  def self.down
    add_column :paackages, :covers, :string
  end
end
