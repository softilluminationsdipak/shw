class ContractStatus < ActiveRecord::Base
	## Relationship
	has_many :customers

	scope :active_status, where('active = ?', true)
  attr_accessible :active, :color_code, :contract_code, :contract_status, :csid, :navigation, :status_url

  validates_presence_of :contract_code, :contract_status
  validates_uniqueness_of :contract_status, :contract_code

  def notification_summary
    "ContractStatus  - #{self.contract_status}"
  end
  
  def edit_url
    "/admin/contract_statuses/edit/#{self.id}"
  end

end
