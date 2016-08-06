class CreateLeads < ActiveRecord::Migration
  def change
    create_table :leads do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :work_phone
      t.string :mobile_phone
      t.string :home_phone
      t.string :address
      t.string :city
      t.string :state
      t.string :zipcode
      t.string :type_of_home
      t.string :square_footage
      t.integer :package_id
      t.text    :optional_coverages
      t.string  :discount_code
      t.string  :credit_card_number
      t.string  :exp_date
      t.string  :billing_address
      t.string  :billing_name
      t.string  :billing_city
      t.string  :billing_state
      t.string  :billing_zipcode
      t.integer :payment_method
      t.timestamps
    end
  end
end
