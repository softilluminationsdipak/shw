class AddCommissionPercentage < ActiveRecord::Migration
  def self.up
  	create_table :agents do |t|
      t.string   	:name
      t.string		:email
      t.integer 	:admin
      t.integer		:commission_percentage, :null => false, :default => 8
      t.string 		:ext
      t.timestamps
    end
  end

  def self.down
    drop_table :agents
  end
end