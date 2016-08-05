class LeadStatus < ActiveRecord::Base
  attr_accessible :active, :color_code, :csid, :lead_code, :lead_status, :navigation

  ## Validations
  validates_presence_of :lead_code, :lead_status
  validates_uniqueness_of :lead_status, :lead_code

  def notification_summary
    "LeadStatus  - #{self.lead_status}"
  end
  
  def edit_url
    "/admin/lead_statuses/edit/#{self.id}"
  end

end
