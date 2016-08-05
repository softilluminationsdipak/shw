class ResultStatus < ActiveRecord::Base
	scope :active_status, where('active = ?', true)
  attr_accessible :active, :color_code, :csid, :navigation, :result_code, :result_status, :status_url

  ## Validations
  validates_presence_of :result_code, :result_status
  validates_uniqueness_of :result_status, :result_code

  def notification_summary
    "ResultStatus  - #{self.result_status}"
  end
  
  def edit_url
    "/admin/result_statuses/edit/#{self.id}"
  end

end
