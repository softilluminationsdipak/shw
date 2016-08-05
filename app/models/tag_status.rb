class TagStatus < ActiveRecord::Base
	scope :active_status, where('active = ?', true)
  attr_accessible :active, :color_code, :csid, :navigation, :status_url, :tag_code, :tag_status

  ## Validations
  validates_presence_of :tag_code, :tag_status
  validates_uniqueness_of :tag_status, :tag_code

  def notification_summary
    "TagStatus  - #{self.tag_status}"
  end
  
  def edit_url
    "/admin/tag_statuses/edit/#{self.id}"
  end

end
