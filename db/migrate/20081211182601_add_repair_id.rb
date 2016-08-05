class AddRepairId < ActiveRecord::Migration
  def self.up
  	create_table :notes do |t|
      t.integer :customer_id, :default => 0
      t.text 	:note_text
      t.integer :timestamp, :default => 0
      t.integer :repair_id
      
      t.timestamps
    end
  end

  def self.down
    drop_table :notes
  end
end
