class AddAddressIdToClaims < ActiveRecord::Migration
  def self.up
    create_table :claims do |t|
      t.integer 	:customer_id
      t.string 		:claim_timestamp
      t.text 		:claim_text
      t.string 		:standard_coverage
      t.integer 	:address_id
      t.timestamps
    end
  end

  def self.down
  	drop_table :claims
  end
end
