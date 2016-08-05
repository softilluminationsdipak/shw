class MerchantAccount < ActiveRecord::Base
  attr_accessible :merchant_name, :merchant_type, :password, :token, :username, :is_default
  
  validates :merchant_name, :merchant_type, :presence => true

  before_create :generate_token

  def generate_token
  	self.token = (0...8).map { (65 + rand(26)).chr }.join
  end

  def default_merchant_account
  	merchant_accounts = MerchantAccount.where("is_default = ?", true)
  	if merchant_accounts.present?
  		merchant_account = merchant_accounts.last
  	else
  		merchant_account = nil
  	end
  end

end
