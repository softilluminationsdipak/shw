class ClaimStatus < ActiveRecord::Base
	scope :active_status, where('active = ?', true)
  attr_accessible :active, :claim_code, :claim_status, :color_code, :csid, :navigation, :claim_url
  validates_presence_of :claim_code, :claim_status
  validates_uniqueness_of :claim_status, :claim_code

  def notification_summary
    "ClaimStatus  - #{self.claim_status}"
  end
  
  def edit_url
    "/admin/claim_statuses/edit/#{self.id}"
  end

end
