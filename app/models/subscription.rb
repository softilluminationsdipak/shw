class Subscription < ActiveRecord::Base
  attr_accessible :amount, :credit_card_id, :customer_id, :end_date, :interval, :occurances, :start_date, :status, :period, :no_end_date

  ## Relationship
  belongs_to :credit_card
  has_one :transaction, :foreign_key => 'sub_id'
  ## Scopes
  scope :of_customer, lambda { |id| { :conditions => ['customer_id = ?', id ] } }

  ## Constant
  PERIOD = ['Day', 'Week', 'Month', 'Year']

  ## Callbacks
  after_create :update_occuranges

  def update_occuranges
    start_date = self.start_date.present? ? self.start_date : Time.now.to_date 
    end_date = self.end_date.present? ? self.end_date : Time.now.to_date 
  	start_date = start_date.to_date 
  	end_date = end_date.to_date 

  	diff = (start_date - end_date).to_i
  	occurance = diff / 6 
  	self.occurances = occurance
    unless self.start_date.present? || self.end_date.present?
      self.start_date = start_date
      self.end_date = end_date
      self.interval = 1  unless self.interval.present?
    end
    unless self.period.present?
      self.period = 'Day'
    end
  	self.save
  end

  def sub_interval
    if self.interval.present?
      "#{self.interval ||= 1} #{self.period ||= 'Day'}"
    else
      "1 Day"
    end
  end

  def sdate
    self.start_date ||= Time.now
  end

  def cancel_subscription
    gw = GwApi.new()
    gw.setLogin("demo", "password");
    r = gw.cancelSubscription('2636861515')
    myResponses = gw.getResponses
    if (myResponses['response'] == '1')
      status = "Approved"
      self.is_cancel_subscription = true
      self.save
    end
  end

  def isActiveSubscription
    self.status.present? && self.status.to_s.downcase == 'approved' && self.is_cancel_subscription == false
  end

  def isCancelSubscription
    self.is_cancel_subscription?
  end

  def self.nmi_login(state)
    state = State.find_by_name(state)
    if state.present?
      if state.merchant_account_id.present?
        merchant_account = state.merchant_account
      else
        merchant_accounts = MerchantAccount.where("is_default = ?", true)
        if merchant_accounts.present?
          merchant_account = merchant_accounts.last
        else
          merchant_account = nil
        end
      end
    else
      merchant_accounts = MerchantAccount.where("is_default = ?", true)
      if merchant_accounts.present?
        merchant_account = merchant_accounts.last
      else
        merchant_account = nil
      end      
    end
    return merchant_account
  end

  def sub_end_date
    if self.no_end_date == true
      'No End Date'
    else
      if self.end_date.present?
        self.end_date.strftime('%m/%d/%Y')
      else
        'No End Date'
      end
    end
  end
end
