class AddLastLoginColumnToAccounts < ActiveRecord::Migration
  def self.up
  	create_table :accounts do |t|
  		t.string 			:email
  		t.string 			:password_hash
  		t.string 			:role
  		t.integer 		:parent_id
  		t.string 			:parent_type
  		t.integer 		:timezone
  		t.string 			:last_login
  		t.timestamps
    end
  end

  def self.down
  	drop_table :accounts
  end
end