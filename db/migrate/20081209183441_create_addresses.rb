class CreateAddresses < ActiveRecord::Migration
  def self.up
    create_table :addresses do |t|
      t.string :street1, :default => '', :null => true
      t.string :street2, :default => '', :null => true
      t.string :street3, :default => '', :null => true
      t.string :city,             :null => false
      t.string :state,            :null => false
      t.string :zip_code,         :null => false
      t.string :country,          :default => "United States of America"
      t.integer :addressable_id
      t.string :addressable_type

      t.timestamps
    end
  end

  def self.down
    drop_table :addresses
  end
end
