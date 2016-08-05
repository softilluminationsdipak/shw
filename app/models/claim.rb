class Claim < ActiveRecord::Base

  
  include ApplicationHelper
  
  belongs_to  :customer
  has_one     :repair
  has_one     :contractor, :through => :repair
  belongs_to  :property, :class_name => "Address", :foreign_key => 'address_id'

  has_many :notes, :as => :notable
  
  accepts_nested_attributes_for :customer
  accepts_nested_attributes_for :contractor
  accepts_nested_attributes_for :repair

  attr_accessible :claim_text, :status_code, :updated_by, :claim_timestamp, :standard_coverage, :agent_name, :status_code, :invoice_status, :invoice_receive, :make, :claim_type, :model, :serial, :age, :size, :condition, :estimate, :buyout, :reimbursement, :b_r_form, :service_call_fee,  :work_order, :invoice_amount, :attach_url, :approve_amount, :ctr_approve_amount, :min_claim, :customer_attributes, :release_received, :release_paid, :ctr_check, :ctr_check_date, :rel_check, :rel_check_date, :contractor_attributes, :repair_attributes, :release_sent, :claimed_item, :other_claimed_item

  attr_accessor :note_image, :note_text
  
  scope :between_dates, lambda { |from, till| { :conditions => { :created_at => from .. till }, :order => "created_at DESC" } }
  scope :with_status_code, where("status_code IS NOT NULL")

  before_save :buyout_or_reimbursement

  INVOICE_STATUS = ["Received", "Approved", "Pmt Processing", "Paid", "Hold"]

  def buyout_or_reimbursement
    if self.reimbursement_changed? && self.reimbursement.to_f > 0.0
       self.buyout = 0.0
    end
    if self.buyout_changed? && self.buyout.to_f > 0.0    
      self.reimbursement = 0.0
    end
  end

  def buyout_or_reimbursement_amount
    if self.reimbursement.present? && self.reimbursement.to_f > 0.0
      return '%.2f' % self.reimbursement.to_f
    else
      return '%.2f' % self.buyout.to_f
    end
    return '0.00' unless self.reimbursement.present? or self.buyout.present?
  end

  def self.statuses_json
    i = -1
    "{" << self.statuses.collect { |k,v| "\"#{k}\":#{v}" }.join(',') << "}"
  end
  
  def self.invoice_status_json
    i = -1
    "{" << Claim::INVOICE_STATUS.collect {|k| "\"#{k}\":'#{k}'" }.join(',') << "}"
  end

  def self.statuses
    ClaimStatus.active_status.map{|p| [p.claim_status, p.csid]}
    #[
    #  ['Not Set', 0], ['Placed by Agent', 1], ['Placed by Customer', 2], ['Waiting for Contract', 3],
    #  ['Contractor Dispatched', 4], ['Re-Dispatched', 13], ['Contractor Reported', 5], ['Approved', 6], 
    #  ['Denied', 7], ['Paid', 12], ['Need More Info.', 8], ['Customer Contacted', 9], ['Send Release', 10],
    #  ['Received Release', 11],['Waiting for pics', 14],['Ineffective', 15],['In Progress',16],['Ready To Report',17],
    #  ['Ready To Dispatch',18],['NeedInfoCustomer',19], ['GoodReview',20], ['ThreatenedAction',21], ['R2R Rita', 22], ['R2R Vadim', 23], ['R2R Rick', 24]
    #]
  end
  
  def self.statuses_abbr
    ClaimStatus.active_status.map(&:claim_status)
    #[ 'Not Set', 'PlacedAgnt', 'PlacedCust', 'ContractWait', 'Disp','Reported', 'Approved', 'Denied', 'MoreInfo', 
    #  'Contacted', 'Send Release', 'RcvdRelease', 'Paid', 'Re-Dispatched', 'PicWait',
    #  'Ineffective','In Progess','ReadyToReport','Ready2Dispatch','NeedInfoCustomer','GoodReview','ThreatenedAction',
    #  'R2R Rita', 'R2R Vadim', 'R2R Rick'
    #]
  end

  def date
    self.created_at || Time.at(self.claim_timestamp.to_i).utc
  end
  
  def status
    if self.status_code.present? && Claim.statuses.rassoc(self.status_code).present?
      Claim.statuses.rassoc(self.status_code)[0] || "Unknown Status!"
    else
      "Unknown Status!"
    end      
  end

  def last_updated_info
    if self.updated_by.present?
      "#{self.updated_at.in_time_zone(EST).strftime("%m/%d/%y %I:%M %p")} (#{self.updated_by})"
    else
      "#{self.updated_at.in_time_zone(EST).strftime("%m/%d/%y %I:%M %p")}"
    end
  end

  def summary
    coverages = []
    (self.standard_coverage || '').split(', ').each do |coverage_id|
      coverages << Coverage.find(coverage_id).coverage_name
    end
    return coverages.join(', ')
  end
  
  def text
    ("<b> #{self.claim_type}:</b></br> #{self.claim_text}".html_safe || '').gsub(/\n/, '<br/>')
  end
  
  def truncated_summary(length=20)
    s = ActionView::Base.full_sanitizer.sanitize(self.claim_text) || ''
    unless s.empty?
      s = s[0...length]
      s << '...' if self.claim_text.length > length
    end
    return s
  end
  
  def notification_summary
    "Claim for #{self.customer.notification_summary} - #{self.truncated_summary}"
  end
  
  def edit_url
    self.customer ? (self.customer.edit_url << '#claims') : ''
  end
  
  def address
    return self.property if self.property
    return self.customer.first_property if self.customer
    return Address.bad_address_for(self)
  end
  
  def claim_number
    customer_id = self.customer.nil? ? 'NOCUSTOMER' : self.customer.contract_number
    "#{customer_id}-#{self.id}"
  end

  def claim_number2
    customer_id = self.customer.nil? ? 'NOCUSTOMER' : self.customer.contract_number
    "#{customer_id}"
  end

  def customer_number_new
    customer_id = self.customer.nil? ? 'NOCUSTOMER' : self.customer.contract_number
    "#{customer_id}"
  end
  
  def customer_name
    self.customer.first_name.present? ? self.customer.first_name.capitalize : ''
  end

  def customer_phone
    "#{clean_phone_number(self.customer.customer_phone)}"
  end

  def customer_state
    self.customer.customer_state.present? ? self.customer.customer_state.upcase : self.customer.properties.last.state.upcase
  end

  def as_json(a=nil,b=nil)
    data = {
      :id => self.id,
      :claim_number => self.claim_number,
      :claim_number2 => self.claim_number2,
      :claim_id2 => self.id, 
      :status_code => self.status_code,
      :date => self.date.in_time_zone(EST).strftime("%m/%d/%y %I:%M %p"),
      :text => ActionView::Base.full_sanitizer.sanitize(self.text),
      :repair => self.repair,
      :property => self.address.to_s,
      :property_lat => self.address.present? ? self.address.lat : '',
      :property_lng => self.address.present? ? self.address.lng : '',
      :agent_name => self.agent_name,
      :updated => self.updated_at ? self.updated_at.in_time_zone(EST).strftime("%m/%d/%y %I:%M %p") : '',
      :customer_id => self.customer_id,
      :customer_id2 => self.customer_number_new,
      :summary => self.truncated_summary(75),
      :status => self.status_code.present? ? self.status : '',
      :customer_phone => "#{clean_phone_number(self.customer.customer_phone)}", 
      :customer_email => self.customer.email,
      :customer_name => self.customer.first_name.capitalize,
      :customer_state => self.customer.customer_state.present? ? self.customer.customer_state.upcase : self.customer.properties.last.state.upcase,
      :invoice_status => self.invoice_status,
      :invoice_receive => self.invoice_receive.present? ? self.invoice_receive.strftime("%m/%d/%Y") : "",
      :invoice_receive_or_edit => self.invoice_receive.present? ? self.invoice_receive.strftime("%m/%d/%Y") : "Edit",
      :invoice_status_or_edit => self.invoice_status.present? ? self.invoice_status : "Edit",
      :claimed_item => self.claimed_item
    }
    data1 = { :status => self.status}  if self.status_code.present? 
    data.merge(data1) if self.status_code.present? 
    return data
  end

  def invoice_receive_date
    self.invoice_receive.present? ? self.invoice_receive.strftime("%m/%d/%Y") : "Edit"
  end

end
