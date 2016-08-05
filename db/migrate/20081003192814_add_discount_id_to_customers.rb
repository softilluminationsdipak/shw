class AddDiscountIdToCustomers < ActiveRecord::Migration
  def self.up
  	create_table :customers do |t|
      t.string   		:email
      t.string 	 		:first_name
      t.string  		:last_name
      t.string		    :customer_address
      t.string    		:customer_city
      t.string			:customer_state
      t.string 			:customer_zip
      t.string			:customer_phone
      t.integer			:coverage_type, :default => 1
      t.string 			:coverage_addon
      t.string			:home_type
      t.string			:pay_amount
	  t.integer			:num_payments, :default => 0
	  t.integer 		:disabled, :default => 1
	  t.integer 		:coverage_end
	  t.datetime 		:coverage_ends_at      
	  t.string 			:subscription_id
	  t.integer 		:validated, :default => 0
	  t.string 			:customer_comment
	  t.text 			:credit_card_number_hash
	  t.string 			:expirationDate
	  t.integer 		:status_id, :default => 0
	  t.integer 		:timestamp
	  t.string 			:ip
	  t.string 			:billing_first_name
	  t.string 			:billing_last_name
	  t.string 			:billing_address
	  t.string 			:billing_city
	  t.string 			:billing_state
	  t.string 			:billing_zip
	  t.integer 		:agent_id
	  t.integer			:discount_id, :null => true
      t.timestamps
    end
  end

  def self.down
    drop_table :customers
  end
end

