class CustomerStatus < ActiveRecord::Base

  ## Scopes

  ## Finding those statuses that are active
	scope :active_status, where('active = ?', true)

  ## Attributes

  ## Giving Mask Assignment Attributes
  attr_accessible :active, :color_code, :customer_code, :customer_status, :navigation, :csid, :status_url

  ## Validations
  validates_presence_of :customer_code, :customer_status
  validates_uniqueness_of :customer_status, :customer_code

  ## Callbacks
  after_save :generate_status_url

  ## Methods
  ## This method is used to generate status url for customer_status that will store in database
  def generate_status_url
  	unless self.status_url.present?
  		status = self.customer_status.delete(' ')
  		self.status_url = "/admin/customers/list/#{status}" 
  		self.save
  	end
  end

  def notification_summary
    "CustomerStatus  - #{self.customer_status}"
  end
  
  def edit_url
    "/admin/customer_statuses/edit/#{self.id}"
  end

end
