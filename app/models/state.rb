class State < ActiveRecord::Base
  attr_accessible :affiliate, :api, :gaq, :name, :tos, :gateway_id

  ## Relaitonship
  belongs_to :gateway
  
  ## Scopes
  scope :active_api, where('api = ?', true)
  scope :active_gaq, where('gaq = ?', true)
  scope :active_affiliate, where('affiliate = ?', true)

  validates_presence_of :name

  before_save :name_in_capital

  def name_in_capital
  	self.name = self.name.upcase
  end

  def notification_summary
    "State - ID - #{self.id} / Name - #{self.name}"
  end
  
  def edit_url
    "/admin/states/edit/#{self.id}"
  end

end
