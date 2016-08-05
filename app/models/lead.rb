class Lead < ActiveRecord::Base
  attr_accessible :address, :city, :email, :first_name, :home_phone, :last_name, :mobile_phone, :square_footage, :state, :type_of_home, :work_phone, :zipcode, :package_id, :optional_coverages, :discount_code, :credit_card_number, :exp_date, :billing_address, :billing_name, :billing_city, :billing_state, :billing_zipcode, :payment_method

  validates_presence_of :address, :city, :email, :first_name, :last_name, :work_phone, :zipcode, :state, :type_of_home, :package_id
  validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i, :on => :create
  validates_format_of :work_phone, with: /\A(\d{10}|\(?\d{3}\)?[-. ]\d{3}[-.]\d{4})\z/
  validates :work_phone,  :numericality => true, :length => { :minimum => 10, :maximum => 10 }
  validates :zipcode,  :numericality => true, :length => { :minimum => 5, :maximum => 5 }
  validates :state, :length => { :minimum => 2, :maximum => 2 }
	
  belongs_to :package
end
