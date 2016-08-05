class ContractorStatus < ActiveRecord::Base
  attr_accessible :active, :contractor_code, :contractor_status, :csid, :navigation

	scope :active_status, where('active = ?', true)

  validates_presence_of :contractor_code, :contractor_status
  validates_uniqueness_of :contractor_status, :contractor_code

  def notification_summary
    "ContractorStatus  - #{self.contractor_status}"
  end
  
  def edit_url
    "/admin/contractor_statuses/edit/#{self.id}"
  end

end
