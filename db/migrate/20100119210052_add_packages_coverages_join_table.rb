class AddPackagesCoveragesJoinTable < ActiveRecord::Migration
  def self.up
    create_table(:coverages_packages, :id => false) do |t|
      t.integer :coverage_id
      t.integer :package_id
    end
    #1..4.times { |i| remove_column(:coverages, "pack_#{i+1}".to_sym) }
    #remove_column :coverages, :premier
    #remove_column :coverages, :sort_order
  end

  def self.down
    drop_table :coverages_packages
    1..4.times { |i| add_column(:coverages, "pack_#{i+1}".to_sym, :boolean, :default => false) }
    add_column :coverages, :premier, :boolean, :default => false
    add_column :coverages, :sort_order, :integer, :default => 0
  end
end
