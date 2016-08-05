class RenewalStatus < ActiveRecord::Base
  ## Attr Accessbile
  attr_accessible :active, :color_code, :csid, :navigation, :renewal_code, :renewal_status, :status_url
  ## Validations
  validates_presence_of :renewal_code, :renewal_status
  validates_uniqueness_of :renewal_status, :renewal_code

  def notification_summary
    "RenewalStatus  - #{self.renewal_status}"
  end
  
  def edit_url
    "/admin/renewal_statuses/edit/#{self.id}"
  end

end
