class Gateway < ActiveRecord::Base
  attr_accessible :login_id, :transaction_key, :is_default, :merchant_name, :gateway_url
  validates_presence_of :login_id, :transaction_key

  def self.default_gateway
  	gateway = Gateway.where("is_default = ?", true)
  	if gateway.present?
  		gateway = gateway.last
  	else
  		gateway = nil
  	end
  end

  def notification_summary
    "Gateway - ID #{self.id} - Login ID - #{self.login_id} and Transaction Key - #{self.transaction_key}"
  end
  
  def edit_url
    "/admin/gateways/edit/#{self.id}"
  end

end
