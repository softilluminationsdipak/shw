require 'openssl'
require 'base64'

class Customer < ActiveRecord::Base

  include ApplicationHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::SanitizeHelper
  
  belongs_to  :package, :foreign_key => 'coverage_type'
  belongs_to  :discount
  belongs_to  :agent
  belongs_to  :cancellation_reason
  belongs_to  :sub_affiliate
  before_save :create_icontact_id
  after_save  :update_icontact_info
  before_create :add_referred_from_from_company

  attr_accessor :cbox
  
  attr_accessible :disabled, :pay_amount, :customer_from, :first_name, :last_name, :email, :customer_phone, :customer_address, :customer_city, :customer_state, :customer_zip, :coverage_type, :coverage_addon, :home_type, :pay_amount, :num_payments, :coverage_end, :coverage_ends_at, :validated, :customer_comment, :credit_card_number_hash, :expirationDate, :timestamp, :ip, :billing_first_name, :billing_last_name, :billing_address, :billing_city, :billing_state, :billing_zip, :from, :service_fee_text_override, :service_fee_amt_override, :wait_period_text_override, :wait_period_days_override, :num_payments_override, :payment_schedule_override, :notes_override, :home_size_code, :home_occupancy_code, :work_phone, :mobile_phone, :call_back_on,  :leadid, :datetimestamp, :is_show_credit_card, :cc_by, :customer_from, :update_by,  :properties_attributes, :coverages_attributes, :coverages, :credit_card_number, :subid, :subscription_id, :contract_status_id, :lead_status_id, :contract_start_date, :contract_duration, :total_billed, :month_fee, :policy_signed, :year, :merchant_name, :gateway_id, :purchase_date
  
  ## Validations
  has_many :fax_assignable_joins, :as => :assignable
  has_many :renewals, :order => 'created_at DESC', :dependent => :destroy
  has_many :transactions, :order => 'created_at DESC', :dependent => :destroy
  has_many :notes, :order => 'created_at DESC', :dependent => :destroy
  #has_many :notes, :as => :notable, :order => 'created_at DESC', :dependent => :destroy
  has_many :claims, :order => 'created_at DESC', :dependent => :destroy
  has_many :addresses, :as => :addressable, :dependent => :destroy
  has_many :properties, :class_name => 'Address', :as => :addressable, :dependent => :destroy, :conditions => { :address_type => 'Property' }
  has_many :credit_cards, :dependent => :destroy
  has_many :ip_tracks, :dependent => :destroy
  has_many :subscriptions, :dependent => :destroy
  
  belongs_to :partner
  belongs_to :contract_status

  has_one  :account, :as => :parent, :dependent => :destroy
  has_one  :billing_address, :class_name => 'Address', :as => :addressable, :dependent => :destroy, :conditions => { :address_type => 'Billing' }
  
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :customer_phone , presence: true
  validates :email, presence: true
  validates :leadid, uniqueness: true, unless: Proc.new { |b| b.leadid.blank? }
  
  accepts_nested_attributes_for :properties, :allow_destroy => true

  ## Scopes 
  scope :with_contract_number, lambda { |s|
    match = s.match(/#{$installation.invoice_prefix}(\d{1,})$/)
    { :conditions => { :id => match[1] }, :limit => 1 }
  }
  
  scope :today, lambda { 
    { :conditions => ["`customers`.created_at > ?", DateTime.now.in_time_zone(EST).beginning_of_day], :order => 'created_at DESC' } 
  }
  scope :yesterday, lambda {
    today = DateTime.now.in_time_zone(EST).beginning_of_day
    { :conditions => { :created_at => today.yesterday .. today }, :order => "created_at DESC" }
  }

  scope :today_yesterday, where("DATE(created_at) >= ?", (Time.now.in_time_zone(EST) - 1.day).to_date )
  # Advanced Searching
  scope :with_name_like, lambda { |n|
    like = '%' << n.split(' ').join('%') << '%'
    { :conditions => ["CONCAT_WS(' ', first_name, last_name) LIKE ?", like] }
  }

  scope :with_first_name,lambda{ |f| where("first_name LIKE ?", f)}

  scope :without_first_name, lambda { |f| { :conditions => ['first_name != ?', f] }}
  
  scope :with_last_name,lambda{ |f| where("last_name LIKE ?", f)}
  
  scope :without_last_name, lambda { |f| { :conditions => ['last_name != ?', f] }}
  
  scope :with_phone, lambda { |p|
    where("REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(customer_phone, '.', ''), ')', ''), '(', '') ,' ', ''), '-', '') LIKE ?", p.gsub(/\(|\)|\s|-|\./, ''))    
  }
  scope :without_phone, lambda { |p|
    { :conditions => ["REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(customer_phone, '.', ''), ')', ''), '(', '') ,' ', ''), '-', '') != ?", p.gsub(/\(|\)|\s|-|\./, '')] }
  }
  
  scope :with_claim_number, lambda { |n|
    id = n.match(/-(\d+)$/)[1].to_i
    { :conditions => ['claims.id = ?', id], :include => :claims }
  }
  
  scope :with_email,lambda{ |e| where("email LIKE ?", e)}

  scope :without_email, lambda { |e| { :conditions => ['email != ?', e] } }
  
  scope :with_street, lambda { |s|
    { :conditions => ['addresses.address_type = "Property" AND addresses.address LIKE ?', "%#{s}%"], :include => :addresses }
  }
  scope :without_street, lambda { |s|
    { :conditions => ['addresses.address_type = "Property" AND addresses.address != ?', s], :include => :addresses }
  }
  
  scope :with_city, lambda { |c|
    { :conditions => ['addresses.address_type = "Property" AND addresses.city = ?', c], :include => :addresses }
  }
  scope :without_city, lambda { |c|
    { :conditions => ['addresses.address_type = "Property" AND addresses.city != ?', c], :include => :addresses }
  }
  
  scope :with_state, lambda { |s|
    { :conditions => ['addresses.address_type = "Property" AND addresses.state = ?', s.downcase], :include => :addresses }
  }
  scope :without_state, lambda { |s|
    { :conditions => ['addresses.address_type = "Property" AND addresses.state != ?', s.downcase], :include => :addresses }
  }
    
  scope :with_zip_code, lambda { |z|
    { :conditions => ['addresses.address_type = "Property" AND addresses.zip_code = ?', z], :include => :addresses }
  }
  scope :without_zip_code, lambda { |z|
    { :conditions => ['addresses.address_type = "Property" AND addresses.zip_code != ?', z], :include => :addresses }
  }
  
  scope :with_status_id, lambda { |sid| { :conditions => { :status_id => sid.to_i }} }
  scope :without_status_id, lambda { |sid| { :conditions => ['status_id != ?', sid.to_i] } }
  
  scope :with_agent_id, lambda { |aid| { :conditions => { :agent_id => aid.to_i }} }
  scope :without_agent_id, lambda { |aid| { :conditions => ['agent_id != ?', aid.to_i] } }
  
  # Other Searches
  
  scope :with_credit_card_number_hash, lambda { |ccnh| { :conditions => { :credit_card_number_hash => ccnh } } }
  
  scope :not_deleted, :conditions => ['status_id != ?', 2]
  scope :with_billing_address, lambda { |ba| { :conditions => { :billing_address => ba } } }
  scope :with_first_and_last_name, lambda { |f,l|
    { :conditions => { :first_name => f, :last_name => l } }
  }
  scope :without_id, lambda { |id| { :conditions => ['id != ?', id] } }

  scope :gaq_with_cc_customer, where('credit_card_number_hash IS NOT NULL && leadid IS NULL')
  scope :gaq_api_customer, where('leadid IS NOT NULL')
  scope :gaq_without_cc_customer, where('credit_card_number_hash IS NULL && leadid IS NULL && home_type IS NOT NULL')
  scope :manual_customer, where('credit_card_number_hash IS NULL && leadid IS NULL && home_type IS NULL')

  scope :lead_by_customer, where('leadid IS NOT NULL')
  scope :list_of_agents, where('agent_id IS NOT NULL')
  scope :not_sub_affiliate_id, where('sub_affiliate_id IS NULL')
  scope :with_sub_affiliate_id, where('sub_affiliate_id IS NOT NULL')

  #scope :with_email_like, lambda { |e|
  #  split = e.split('@'); query = "%#{split[0].to_s}%@%#{split[1].to_s}%"
  #  { :conditions => ['email LIKE ?', query] }
  #}
  
  def self.statuses2
    CustomerStatus.active_status.map{|p| [p.customer_status, p.csid]}
  end

  def self.statuses22
    CustomerStatus.active_status.map(&:customer_status)
  end

  def c_status
    if Customer.statuses2.rassoc(self.status_id)
      Customer.statuses2.rassoc(self.status_id)[0] || "Unknown Status!"
    else 
      "Unknown Status!"
    end
  end

  def Customer.telecom_number_strip_condition(field, value)
    ["REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(`#{field}`, '.', ''), ')', ''), '(', '') ,' ', ''), '-', '') = ?", value.gsub(/\(|\)|\s|-|\./, '')]
  end
  
  def formatted_home_type
    Package.home_type_names[self.home_type] || 'Single-Family'
  end
  
  @@home_occupancies = Dictionary[
    0,'Single Family',
    1,'2 Family',
    2,'3 Family',
    3,'4 Family',
    4,'Condominium'
  ]
  def self.home_occupancies; @@home_occupancies; end
  
  @@home_sizes = Dictionary[0,'Less than 5,000 sq ft.', 1,'More than 5,000 sq ft.'].freeze
  def self.home_sizes; @@home_sizes; end
  def self.home_size_options
    json = []
    @@home_sizes.each do |code, size|
      json << "'#{size}': #{code}"
    end
    "{#{json.join(', ')}}"
  end

  def cust_city
    self.customer_city.present? ? self.customer_city.gsub(",", " ") : ''
  end

  def cust_addres
    self.customer_address.present? ? self.customer_address.gsub(",", " ") : ''    
  end

  def csv_property_address
    if self.addresses.present?
      return "#{self.addresses.last.address} #{self.addresses.last.address2} #{self.addresses.last.address3}"
    else
      return ''
    end
  end

  def csv_zipcode
    if self.addresses.present?
      return "#{self.addresses.last.zip_code}"
    else
      return ''
    end
  end

  def csv_country
    if self.addresses.present?
      return "#{self.addresses.last.country}"
    else
      return ''
    end
  end

  def csv_geocoded_address
    if self.addresses.present?
      if self.addresses.last.geocoded_address.present?
        return "#{self.addresses.last.geocoded_address.gsub(',', '.')}"
      else
        return ''
      end
    else
      return ''
    end
  end


  def cust_fullname
    fullname = "#{self.first_name} #{self.last_name}"
    fullname = fullname.gsub(",", " ")
    return fullname
  end

  def claim_type_dropdown
    if self.package.present? && self.package.coverages.present? 
      cov = self.package.coverages.map(&:coverage_name)
    else
      cov = []
    end
    if self.coverages.present?
      cvname = self.coverages.map(&:coverage_name)
    else
      cvname = []
    end
    cov + cvname
  end

  def self.to_csv(options = {}, start_date = nil, end_date = nil)
    CSV.generate(options) do |csv|
      csv << ["SHW#", "LeadId", "SubId", "Fullname", "Address", "City", "State", "Zip", "Phone", "Email", "Status", "Created-At"]
      all.each do |customer|
        csv << [customer.id, customer.leadid, customer.subid, customer.cust_fullname, customer.cust_addres, customer.cust_city, customer.customer_state, customer.customer_zip, customer.customer_phone, customer.email, customer.c_status, customer.created_at.strftime("%m/%d/%Y")] 
      end
    end
  end

  def self.to_csv2(options = {}, start_date = nil, end_date = nil)
    CSV.generate(options) do |csv|
      csv << ["LeadId", "SubId","First Name", "Last Name", "Phone", "Email", "Address", "City", "State", "Zip", "IP", "TimeStamp"]
      all.each do |customer|
        csv << [customer.leadid, customer.subid, "#{customer.first_name}","#{customer.last_name}",  customer.customer_phone, customer.email, customer.customer_address, customer.customer_city, customer.customer_state, customer.customer_zip, customer.ip, customer.datetimestamp ] 
      end
    end
  end


  def self.to_csv3(options = {}, state = nil, status = nil, full_property_info=nil)
    CSV.generate(options) do |csv|
      if full_property_info == true
        csv << ["Id", "Email", "First Name", "Last Name", "Phone Number", "Status ID", "Created At", "Updated At", "address".upcase, "City".upcase, "State".upcase,"Zipcode".upcase,"Country".upcase, "# of Transactions", "Total Transactions", "Transaction Date"]
      else
        csv << ["Id", "Email", "First Name", "Last Name", "Phone Number","Status ID", "Created At", "Updated At", "City", "State", "# of Transactions", "Total Transactions", "Transaction Date"]
      end
      all.each do |customer|
        if customer.transactions.present?
          if full_property_info == true
            csv << [customer.id, customer.email, "#{customer.first_name}","#{customer.last_name}", customer.customer_phone, customer.c_status, customer.created_at.strftime("%m-%d-%y"), customer.updated_at.strftime("%m-%d-%y"), customer.csv_property_address.upcase, customer.cust_address_last_city.upcase, customer.addresses.last.state.upcase, customer.csv_zipcode.to_s.upcase, customer.csv_country.upcase, customer.transactions.count, customer.transaction_total_amount_with_success, customer.transaction_first_approve_date] 
          else
            csv << [customer.id, customer.email, "#{customer.first_name}","#{customer.last_name}", customer.customer_phone, customer.c_status, customer.created_at.strftime("%m-%d-%y"), customer.updated_at.strftime("%m-%d-%y"), customer.cust_address_last_city, customer.addresses.last.state, customer.transactions.count, customer.transaction_total_amount_with_success, customer.transaction_first_approve_date] 
          end
        else
          if full_property_info == true
            csv << [customer.id, customer.email, "#{customer.first_name}","#{customer.last_name}", customer.customer_phone, customer.c_status, customer.created_at.strftime("%m-%d-%y"), customer.updated_at.strftime("%m-%d-%y"), customer.csv_property_address.upcase, customer.cust_address_last_city.upcase, customer.addresses.last.state.upcase, customer.csv_zipcode, customer.csv_country.upcase, customer.transactions.count, "", ""] 
          else
            csv << [customer.id, customer.email, "#{customer.first_name}","#{customer.last_name}", customer.customer_phone, customer.c_status, customer.created_at.strftime("%m-%d-%y"), customer.updated_at.strftime("%m-%d-%y"), customer.cust_address_last_city, customer.addresses.last.state, customer.transactions.count, "", ""] 
          end
        end
      end
    end
  end

  def self.to_csv4(options = {})
    CSV.generate(options) do |csv|
      csv << ["CustomerId", "Fullname", "Customer State", "NumOfPayments", "Total", "CreatedDate"]
      all.each do |customer|
        csv << [customer.id, customer.cust_fullname, customer.cust_state, customer.transactions.count, customer.total_transaction_amount, customer.created_at.strftime("%m/%d/%Y")] 
      end
    end
  end

  def self.to_csv5(options = {})
    CSV.generate(options) do |csv|
      csv << ['Contract #', 'Fullname', 'Email', 'Address', 'City', 'State', 'Zip', 'Customer Phone', 'Home Type', 'Status', 'IP Address', 'Work Phone', 'Mobile Phone', 'Updated By', 'Created At']
      all.each do |customer|
        csv << [customer.contract_number, customer.cust_fullname, customer.email, customer.customer_address, customer.customer_city, customer.cust_state, customer.zip_code, customer.customer_phone, customer.home_type, customer.c_status, customer.ip, customer.work_phone, customer.mobile_phone, customer.last_updated_info, customer.created_at.strftime("%m/%d/%Y")]
      end
    end
  end

  def cust_address_last_city
    self.addresses.present? ? self.addresses.last.city.gsub(","," ") : ''
  end

  def cust_state
    self.customer_state.present? ? self.customer_state.upcase : self.last_property_state
  end

  def total_transaction_amount
    self.transactions.present? ? "$ #{self.transactions.sum(&:amount).round(2)}" : "$ 0.0"
  end

  def transaction_total_amount_with_success
    self.transactions.where("transactions.response_code = 1").sum(&:amount)
  end

  def transaction_first_approve_date
    dt = self.transactions.where("transactions.response_code = 1").first
    if dt.present? && dt.created_at.present? 
      return dt.created_at.strftime("%m-%d-%y %M:%H:%S") 
    else
      return " "
    end
  end

  def home_size
    Customer.home_sizes[self.home_size_code] || Customer.home_sizes.first
  end
  
  def service_fee_text_override!
    self.service_fee_text_override.nil? || self.service_fee_text_override.empty? ? 'sixty' : self.service_fee_text_override
  end
  def service_fee_amt_override!
    "%.2f" % (self.service_fee_amt_override.nil? || self.service_fee_amt_override == 0 ? 60.0 : self.service_fee_amt_override)
  end
  
  def wait_period_text_override!
    self.wait_period_text_override.nil? || self.wait_period_text_override.empty? ? 'thirty' : self.wait_period_text_override
  end
  def wait_period_days_override!
    self.wait_period_days_override.nil? || self.wait_period_days_override == 0 ? 30 : self.wait_period_days_override
  end
  
  def contract_overrides
    attrs = [ :service_fee_text_override, :service_fee_amt_override,
              :wait_period_text_override, :wait_period_days_override,
              :num_payments_override,     :payment_schedule_override, 
              :notes_override, :month_fee, :year, :purchase_date, :last_updated_info ]
    overrides = {}
    attrs.each { |attrib| overrides[attrib] = self[attrib] }
    return overrides
  end

  def service_fee
    "$#{self.service_fee_amt_override!.gsub(/\.00/, '')} (#{self.service_fee_text_override!.titleize} Dollars)"
  end
  
  def payment_schedule
    "#{self.num_payments_override || self.num_payments} #{self.payment_schedule_override}"
  end
  
  @@payment_schedules = ['','Monthly Payment(s)', 'Consecutive Monthly Payment(s)', 'Quarterly Payment(s)', 'Semi-Annual Payment(s)', 'Annual Payment(s)', 'Payment(s)']
  def self.payment_schedules; @@payment_schedules; end
  
  # TODO There must be a better way to do this;
  #      we need to use an array because we need it in order
  def payment_schedule_options_json
    json = []
    @@payment_schedules.each_with_index do |s, i|
      json << (i == 0 ? "'': null" : "'#{s}': '#{s}'")
    end
    return "{#{json.join(', ')}}"
  end
  
  def first_billing_address

    billing_addr_empty = self.billing_address.address.empty? rescue true

    if !self.billing_address.nil? && !billing_addr_empty
      self.billing_address
    elsif not self.attributes[:billing_address].nil?
      Address.new({
        :address  => self.attributes[:billing_address],
        :city     => self.billing_city,
        :state    => self.billing_state,
        :zip_code => self.billing_zip
      })
    elsif not self.credit_cards.first.nil?
      self.credit_cards.first.address
    else
      self.first_property
    end
  end
  
  def contract_term_years
    !self.renewals.empty? && self.renewals.first.duration > 0 ? self.renewals.first.duration : 1
  end
  
  def contract_url
    "https://#{ENV['DOMAIN_CONFIG']}/contract/#{self.contract_number.delete('#')}"
  end
  
  def edit_url
    "/admin/customers/edit/#{self.id}"
  end
  
  def notification_summary
    "#{self.contract_number} #{self.name}"
  end

  def last_property_state
    if self.properties.present? && self.properties.last.present? && self.properties.last.state.present?
      self.properties.last.state.upcase
    elsif self.properties.present? && self.properties.first.present? && self.properties.first.state.present?
      self.properties.first.state.upcase
    else
      ''
    end 
  end

  def last_updated_info
    if self.update_by.present?
      "#{self.updated_at.strftime("%m/%d/%y %H:%M ")} (#{self.update_by})"
    else
      "#{self.updated_at.strftime("%m/%d/%y %H:%M")} (#{self.first_name})"
    end
  end

  def as_json(a=nil,b=nil)
    {
      :id               => self.id,
      :contract         => self.contract_number,
      :updated          => self.updated_at ? self.updated_at.in_time_zone(EST).strftime("%m/%d/%y %I:%M %p") : '',
      :date             => self.date ? self.date.in_time_zone(EST).strftime("%m/%d/%y %I:%M %p") : 'No Date',
      :from             => self.from,
      :name             => self.name,
      :email            => self.email,
      :status           => self.c_status,
      :standing         => self.transactional_standing,
      :updated_at       => self.updated_at.strftime("%m/%d/%y %H:%M %p"),
      :isWebOrder       => self.web_order?,
      :isduplicate      => self.duplicate_email_record?,
      :isduplicate_with24_hr    => self.duplicate_and_within_24_hour?,
      :isWebOrderCompleted      => self.web_order_completed?,
      :phoneNumber          => "#{clean_phone_number(self.customer_phone)}", 
      :callBackOn           => self.call_back_on.try(:strftime, '%m/%d/%Y'),
      :last_updated_info    => self.last_updated_info,
      :customer_state       => self.customer_state.present? ? self.customer_state.upcase : self.last_property_state,
      :contract_status_id => self.contract_status_id,
      :lead_status_id => self.lead_status_id,
      :month_fee => self.months_free.present? ? self.months_free : '-',
      :policy_signed => self.policy_signed,
      :year => self.year.to_s,
      :purchase_date => self.purchase_date.present? ? self.purchase_date : ''
    }
  end
  
  def first_property
    self.properties.empty? ? nil : self.properties.first
  end
  
  def Customer.id_for_status(status)
    
    status_list = {}
    CustomerStatus.active_status.each do |t|
      surl = t.status_url.present? ? t.status_url.split('/').last.to_sym : nil
      if surl.present?
        status_list = status_list.merge({ surl  =>  t.csid })
      end
    end
    return status_list[status.to_sym] || 0
  end
  
  def Customer.formatted_status_array
    CustomerStatus.active_status.map{|p| [p.customer_status, p.csid]}
  end
  
  def Customer.formatted_contract_status_array
    ContractStatus.all.map{|p| [p.contract_status, p.csid]}
  end

  def Customer.formatted_lead_status_array
    LeadStatus.all.map{|p| [p.lead_status, p.csid]}
  end

  def esigned?
    self.account and self.account.signature_hash
  end
  
  def cancel_reason
    self.cancellation_reason.nil? ? '--' : self.cancellation_reason.reason
  end
  
  def contract_number
    #if self.id.to_i >= 100000
    #  "##{$installation.invoice_prefix2}#{self.id.to_s.rjust(5, '0')}"
    #else
  	 "##{$installation.invoice_prefix}#{self.id.to_s.rjust(5, '0')}"
    #end
  end
  
  def _contract_number
    self.contract_number.delete('#')
  end
  
  def dashed_contract_number
    self.contract_number.split(/(\d+)/).join('-')
  end
  
  def _dashed_contract_number
    self.dashed_contract_number.delete('#')
  end
  
  def name
    "#{self.first_name} #{self.last_name}"
  end
  alias to_s name
  
  def full_coverage_address
    "#{self.customer_address} #{self.customer_city}, #{self.customer_state}, #{self.customer_zip}"
  end
  
  def date
    begin
      self.created_at || (Time.at(self.timestamp).utc if timestamp)
    rescue
      Time.now
    end
  end
  
  def cust_purchase_date
    if self.purchase_date.present?
      return  Date.strptime(self.purchase_date, '%m/%d/%Y').to_date
    else
      unless self.transactions.present?
        return self.date.to_date 
      else 
        if self.transactions.present? && self.transactions.approved.present?
          return self.transactions.approved.last.created_at.in_time_zone(EST).strftime("%d/%m/%Y").to_date
        else
          return self.date.to_date
        end
      end
    end
  end

  def months_free
    self.month_fee
  end

  def status
    case self.status_id
    when 0
      "New Customer"
    when 1
      "Left Message"
    when 2
      "Deleted"
    when 3
      "Follow Up"
    when 4
      "Completed Order"
    when 5
      "Cancelled"
    when 6
      "Proforma"
    when 7
      "To Be Billed"
    when 8
      "Requested Refund"
    when 9
      "To be refunded"
    when 10
      "Declined"
    when 11
      "Email List"
    when 12
      "Do Not Call"
    when 13
      "Disconnected"
    when 14
      "Refused Renewal"
    end
  end
  
  def rate_mode
    case self.num_payments.to_i % (self.contract_term_years * 12)
    when 0
      "MONTHLY"
    when 1
      "ANNUAL"
    when 4
      "QUARTERLY"
    else
      "SEMI-ANNUAL"
    end
  end
  
  def formatted_annual_rate
    "$%.2f" % case self.num_payments.to_i % (self.contract_term_years * 12)
    when 0
      self.pay_amount.to_f * 12
    else
      self.pay_amount.to_f * self.num_payments.to_i
    end
  end
  
  def web_order?
    #self.subscription_id && self.subscription_id.to_i > 0
    self.credit_cards.present? && self.credit_cards.where("last_4 IS NOT NULL").count >= 1
  end

  def duplicate_email_record?
    ccount = Customer.where("email = ?", self.email).count
    ccount > 1
  end

  def duplicate_and_within_24_hour?
    ccount = Customer.where("DATE(created_at) = ? && email = ?", Time.now.to_date, self.email).count
    customer = Customer.where("DATE(created_at) = ? && email = ?", Time.now.to_date, self.email).last
    if ccount > 1
      return customer.id
    else
      return false
    end
  end

  def web_order_completed?
    self.status_id == 4 && self.credit_card_number.length == 15
  end
  
  def class_for_status
    'webOrder' if self.web_order?
  end
  
  def coverages=(hash)
    self.coverage_addon = hash.collect { |k,v| k if v != 'false' }.delete_if { |x| x == nil }.join(', ')
  end
  
  def coverages
    if self.coverage_addon.nil? or self.coverage_addon.empty? then return [] end    
    coverage_ids = self.coverage_addon.split(", ")
    coverages = coverage_ids.collect { |id| Coverage.find_by_id(id) }.compact
    return coverages
  end
  
  def coverage_text
    self.package_covers + (", #{self.coverage_option_names}" if self.coverages.length > 0).to_s
  end
  
  def coverage_option_names
    self.coverages.collect { |c| c.coverage_name }.join(', ')
  end
  
  def has_coverage?(coverage)
    if self.coverage_addon
      return self.coverage_addon.split(', ').include?(coverage.id.to_s)
    else
      return false
    end
  end
  
  def package_covers
    self.package.covers if self.package
  end
  
  def package_name
  	self.package.package_name if self.package
  end
  
  def package_price
    ht = (self.home_type.nil? or self.home_type.empty?) ? 'single' : self.home_type
  	if self.package.present?
      pprice = self.package.send("#{ht}_price")
      unless pprice.present?
        pprice = 499.99 
      end
    else
      pprice = 499.99
    end
    return pprice
  end
  
  def list_price
    total = self.package_price
    total = 0.0 unless total.present?
    total += (self.coverages.collect { |c| c.price }).sum
    return total
  end
  
  def credit_card_number
    if self.credit_card_number_hash and not self.credit_card_number_hash.empty?
      private_key = OpenSSL::PKey::RSA.new(File.read('app/security/private.pem'), 'aENtkiJ0')
      return private_key.private_decrypt(Base64.decode64(self.credit_card_number_hash))
    else
      return ''
    end
  end
  
  def credit_card_number=(number)
    public_key = OpenSSL::PKey::RSA.new(File.read('app/security/public.pem'));
    self.credit_card_number_hash = Base64.encode64(public_key.public_encrypt(number))
  end
  
  def credit_card_number_last_4
    number = self.credit_card_number
    (number[-4..-1] || "").rjust(number.length, '*')
  end
  
  def phone_number_last_4
    phone_number = self.work_phone
    phone_number[phone_number.length - 4 ,4]
  end

  def coverage_has_ended?
    Time.now > self.coverage_ends_at
  end
  
  def grant_web_account
    unless self.account.nil? then return "#{self.name} already has a web account" end
    if self.email.nil? or self.email.empty? then return "#{self.name} must have a valid email address." end
    
    password = Account.generate_random_password #length is 8
    self.create_account({
      :email => self.email,
      :password => password,
      :role => 'customer',
      :parent_id => self.id,
      :parent_type => 'Customer',
      :timezone => '-5'
    })
    if self.account.nil?
      return "A web account could not be created for #{self.name}"
    else
      return password
    end
  end
  
  def transactional_standing
    self.transactions.first.result.downcase.gsub(/\s/, '') if self.transactions.first
  end
  
  def related_customers
    by_hash = Customer.with_credit_card_number_hash(self.credit_card_number_hash)
    by_email = Customer.with_email(self.email)
    #by_billing = self.billing_address == '' || self.billing_address.nil? ? [] : Customer.with_billing_address(self.billing_address)
    by_name = Customer.with_first_and_last_name(self.first_name, self.last_name)

    return by_hash | by_email | by_name
  end
  
  def can_be_purged?
    self.transactions.empty? and self.notes.empty? and self.claims.empty?
  end
  
  def default_grouping_action(viewed_customer)
    if self.status_id == 2 && self.can_be_purged?
      return 'purge'
    elsif self.full_coverage_address != viewed_customer.full_coverage_address
      return 'property'
    elsif self.status_id != 2
      return 'primary'
    else
      return 'ignore'
    end
  end
  
  def coverage_address?
    !(self.customer_address.nil? or self.customer_address.empty?)
  end
  
  def billing_address?
    begin
      !(self.billing_address.nil? or self.billing_address.empty?)
    rescue
    end
  end
  
  def convert_addresses!
    Address.transaction do
      if self.coverage_address?
        self.addresses.create({
          :address => self.customer_address,
          :city => self.customer_city,
          :state => self.customer_state,
          :zip_code => self.customer_zip,
          :address_type => 'Property'
        })
        self.update_attributes({
          :customer_address => nil,
          :customer_city => nil,
          :customer_state => nil,
          :customer_zip => nil
        })
      end
      if self.billing_address?
        self.addresses.create({
          :address => self.billing_address,
          :city => self.billing_city,
          :state => self.billing_state,
          :zip_code => self.billing_zip,
          :address_type => 'Billing'
        })
        self.update_attributes({
          :billing_address => nil,
          :billing_city => nil,
          :billing_state => nil,
          :billing_zip => nil
        })
      end
      self.properties.each do |p|
        self.addresses.create({
          :address => p.address,
          :city => p.city,
          :state => p.state,
          :zip_code => p.zip,
          :address_type => 'Property'
        })
        p.destroy
      end
      self.addresses
    end
  end
  
  def build_and_nullify_property
    p = Property.new({
      :address => self.customer_address,
      :city => self.customer_city,
      :state => self.customer_state,
      :zip => self.customer_zip
    })
    self.update_attributes({
      :customer_address => nil,
      :customer_city => nil,
      :customer_state => nil,
      :customer_zip => nil
    })
    return p
  end
  
  def update_coverage_address_and_drop_first_property 
    p = self.properties.first
    if p.nil? then return end
      
    self.update_attributes({
      :customer_address => p.address,
      :customer_city => p.city,
      :customer_state => p.state,
      :customer_zip => p.zip_code
    })
    
    p.destroy
  end
  
  def address
    self.properties.empty? ? '' : self.properties.first.address
  end
  
  def city
    self.properties.empty? ? '' : self.properties.first.city
  end
  
  def state
    self.properties.empty? ? '' : self.properties.first.state
  end
  
  def zip_code
    self.properties.empty? ? '' : self.properties.first.zip_code
  end
  
  def full_address
    [self.address, self.city, self.state, self.zip_code].reject { |x| x == '' }.join(', ')
  end
  
  def to_icontact_record
    <<-XML
    <?xml version="1.0"?>
    <contact id="#{self.icontact_id}">
      <fname>#{self.first_name}</fname>
      <lname>#{self.last_name}</lname>
      <email>#{self.email}</email>
      <address1>#{self.billing_address.address if self.billing_address}</address1>
      <address2>#{self.billing_address.address2 if self.billing_address}</address2>
      <city>#{self.billing_address.city if self.billing_address}</city>
      <state>#{self.billing_address.state if self.billing_address}</state>
      <zip>#{self.billing_address.zip_code if self.billing_address}</zip>
      <phone>#{self.customer_phone}</phone>
    </contact>
    XML
  end
  
  def enqueue_follow_up_list_action(action)
    IContactRequest.create({
      :path => "contact/#{self.icontact_id}/subscription/#{IContactRequest::FOLLOW_UP_LIST_ID}",
      :put => IContactRequest.follow_up_subscription(action == :add)
    })
  end
  
  def enqueue_left_message_list_action(action)
    IContactRequest.create({
      :path => "contact/#{self.icontact_id}/subscription/#{IContactRequest::LEFT_MESSAGE_LIST_ID}",
      :put => IContactRequest.left_message_subscription(action == :add)
    })
  end

  def state_wise_tos
    state = State.find_by_name(self.state)
    tos = state.tos if state.present? 
    if state.present? && tos.present? 
      tos_content = Content.find(tos)
    else
      tos_content = Content.find_by_slug("terms_of_service")
    end
    return tos_content
  end

    ## --------------------------------------------------
  def save_contract_pdffile#(customer_id)
    @customer = self
    customer_id = self.id.to_s
    if @customer.nil?
       return false
    end
    @contract_number    = @customer.dashed_contract_number.delete('#')
    @payment            = "$%.2f" % @customer.pay_amount.to_f
    @purchase_date      = @customer.cust_purchase_date #(@customer.transactions.approved.empty? ? @customer.date : @customer.transactions.approved.last.created_at.in_time_zone(EST)).strftime("%B %d, %Y")
    @home_type          = @customer.formatted_home_type
    @home_size          = @customer.home_size
    @billing_address    = @customer.first_billing_address.to_s_for_contract
    @coverage_address   = @customer.first_property.to_s_for_contract
    state               = State.find_by_name(@customer.state)
    if state.present? and state.tos.present?
      @tos                = Content.tos_for2(@customer) #Content.tos_for_dupl(@customer, state.tos)
    else
      @tos                = Content.tos_for(@customer)
    end    
    #@tos                = Content.tos_for2(@customer)
    num_payments        = @customer.num_payments_override == 0 ? '' : (@customer.num_payments_override || @customer.num_payments)
    @payment_schedule   = "#{num_payments} #{@customer.payment_schedule_override}"
    @package_coverage_sets = Rails.env == 'test' ? [["None"]] : (@customer.package.coverages.empty? ? ["None"] : @customer.package.coverages.collect(&:coverage_name).collect(&:upcase)).each_slice(3).to_a
    # If coverages is empty, we have to make it [[]] or else Prawn will complain
    @optional_coverage_sets = Rails.env == 'test' ? [["None"]] : (@customer.coverages.empty? ? ["None"] : @customer.coverages.collect(&:coverage_name).collect(&:upcase)).each_slice(3).to_a
    purchaseable_coverages = Rails.env == 'test' ? [["None"]] :  Coverage.all_optional - @customer.coverages
    @purchaseable_optional_coverage_sets = Rails.env == 'test' ? [["None"]] : (purchaseable_coverages.empty? ? ["None"] : purchaseable_coverages.collect(&:coverage_name).collect(&:upcase)).each_slice(3).to_a

    require 'prawn'
    doc = Prawn::Document.generate("#{Rails.root}/contracts/contract_#{customer_id}.pdf",:margin => [20, 20, 40, 20]) do |pdf|
      tos_font  = "#{Rails.root}/app/views/admin/customers/Arial Narrow.ttf"
      body_font = 'Helvetica'
      body_font_size  = 10
      table_font_size = 9.5
      three_column_table_options = {
        :cell_style => {
           :border_width => 1, :size => table_font_size, :align => :center,
           :padding => [2,0,2,0]
         },
        :column_widths => { 0 => 190, 1 => 190, 2 => 190 }
      }

      draw_header_box = Proc.new {
        pdf.table([[$installation.name.upcase], ['POLICY HOLDER AGREEMENT']],
                  :cell_style => {:align => :center, :padding => [1,0,1,0]},
                  :position           => :center,
                  :column_widths      => { 0 => 570 }
                  )
        pdf.move_down 20
      }

      draw_signature_lines = Proc.new { |y|
        pdf.font body_font, :size => body_font_size, :style => :normal
        pdf.text_box "I AGREE TO THE TERMS AND CONDITIONS SET FORTH HEREIN. PLEASE SIGN ALL OF THE ATTACHED PAGES AND FAX THEM TO #{$installation.fax} OR YOU MAY SCAN AND EMAIL THEM TO #{$installation.customercare_email}", :at => [0, y+55]
        pdf.stroke_line [0,y,   200,y]
        pdf.text_box 'POLICY HOLDER (PRINT)',     :at => [5,y-10]
        pdf.stroke_line [210,y, 440,y]
        pdf.text_box 'POLICY HOLDER (SIGNATURE)', :at => [215,y-10]
        pdf.stroke_line [450,y, 573,y]
        pdf.text_box 'DATE',                      :at => [455,y-10]
      }

      pdf.font_size = body_font_size
      pdf.font body_font
      pdf.line_width = 1

      # Policy Info

      draw_header_box.call

      if @customer.month_fee.present? && @customer.month_fee.to_i >= 1
        data = [
              ['POLICY #:',             @contract_number,                     '',                 ''],
              ['POLICY HOLDER:',        @customer.name.upcase,                '',                 ''],
              ['COVERAGE ADDRESS:',     @coverage_address,                    'BILLING ADDRESS:', @billing_address],
              ['RATE:',                 @customer.formatted_annual_rate,      'CUSTOMER EMAIL:',  @customer.email ],
              ['PAYMENT:',              @payment,                             'TYPE OF HOME:',    @home_type      ],
              ['PAYMENT SCHEDULE:',     @payment_schedule,                    'SIZE OF HOME:',    @home_size      ],
              ['PURCHASE DATE:',        @purchase_date,                       'MONTH FREE',       "#{@customer.month_fee} Months" ],
              ['SERVICE CALL FEE', @customer.service_fee_amt_override.to_i == 0 ? "$60" : "$#{@customer.service_fee_amt_override.to_i}", 'CONTRACT TERM',         pluralize(@customer.year, 'Year')],
              ['NOTES:',                {:content => @customer.notes_override.to_s.strip }]
        ]
      else
        if @customer.year.to_i >= 1
          data = [
              ['POLICY #:',             @contract_number,                     '',                 ''],
              ['POLICY HOLDER:',        @customer.name.upcase,                '',                 ''],
              ['COVERAGE ADDRESS:',     @coverage_address,                    'BILLING ADDRESS:', @billing_address],
              ['RATE:',                 @customer.formatted_annual_rate,      'CUSTOMER EMAIL:',  @customer.email ],
              ['PAYMENT:',              @payment,                             'TYPE OF HOME:',    @home_type      ],
              ['PAYMENT SCHEDULE:',     @payment_schedule,                    'SIZE OF HOME:',    @home_size      ],
              ['PURCHASE DATE:',        @purchase_date,                       'CONTRACT TERM',   pluralize(@customer.year, 'Year')],
              ['SERVICE CALL FEE', @customer.service_fee_amt_override.to_i == 0 ? "$60" : "$#{@customer.service_fee_amt_override.to_i}", '', ''],
              ['NOTES:',                {:content => @customer.notes_override.to_s.strip }]
          ]          
        else          
          data = [
              ['POLICY #:',             @contract_number,                     '',                 ''],
              ['POLICY HOLDER:',        @customer.name.upcase,                '',                 ''],
              ['COVERAGE ADDRESS:',     @coverage_address,                    'BILLING ADDRESS:', @billing_address],
              ['RATE:',                 @customer.formatted_annual_rate,      'CUSTOMER EMAIL:',  @customer.email ],
              ['PAYMENT:',              @payment,                             'TYPE OF HOME:',    @home_type      ],
              ['PAYMENT SCHEDULE:',     @payment_schedule,                    'SIZE OF HOME:',    @home_size      ],
              ['PURCHASE DATE:',        @purchase_date,                       '',                 ''],
              ['SERVICE CALL FEE', @customer.service_fee_amt_override.to_i == 0 ? "$60" : "$#{@customer.service_fee_amt_override.to_i}", '', ''],
              ['NOTES:',                {:content => @customer.notes_override.to_s.strip }]
          ]
        end
      end
      pdf.table(data,
                :cell_style => {:border_width => 0, :size => table_font_size, :padding => [3,0,3,0]},
                :column_widths => { 0 => 120, 1 => 180, 2 => 100, 3 => 170 })

      pdf.stroke_line [0,500, 573,500]
      pdf.stroke_line [0,498, 573,498]
      pdf.move_down 35

      pdf.font_size = body_font_size
      pdf.font body_font, :style => :bold

      pdf.text "PLAN SELECTED: #{@customer.package.package_name.upcase unless Rails.env == 'test'}"
      pdf.text "This #{$installation.name} coverage plan will protect the following\nhome systems and appliances:".upcase, :align => :center


      pdf.font body_font, :style => :normal
      pdf.table @package_coverage_sets, three_column_table_options

      pdf.move_down 10
      pdf.text 'OPTIONAL COVERAGE SELECTED:', :style => :bold
      pdf.table @optional_coverage_sets, three_column_table_options

      pdf.move_down 10
      pdf.text "Please call us at #{$installation.phone} to take advantage of the optional coverage below:".upcase, :align => :center, :style => :bold

      pdf.table @purchaseable_optional_coverage_sets, three_column_table_options

      pdf.stroke_line [0,220, 573,220]
      pdf.stroke_line [0,218, 573,218]
      pdf.move_down 45

      draw_signature_lines.call(130)

      pdf.move_down 130
      pdf.stroke_color '000000'

      pdf.bounding_box [0, 60], :width => 573, :height => 50 do
        pdf.text_box "TO ENROLL ANOTHER PROPERTY OR TO REQUEST SERVICES, PLEASE CALL OR VISIT US 24 HOURS A DAY, 7 DAYS", :at => [5, 36]
        pdf.text_box "A WEEK, 365 DAYS A YEAR AT:", :at => [5, 25]
        pdf.text_box $installation.phone,           :at => [90,  10], :style => :bold
        pdf.text_box $installation.domain,          :at => [330, 10], :style => :bold

        pdf.stroke_bounds
      end     

      # Terms of Service

      pdf.start_new_page

      draw_header_box.call

      #pdf.font tos_font, :size => 8
      pdf.font_size = 8
      pdf.text strip_tags(@tos)
      pdf.move_down 150
      draw_signature_lines.call(40)
      # Footer
      #pdf.font tos_font, :size => 8
      pdf.font_size = 7
      pdf.number_pages "Page <page> of <total>", :at => [250, -20]
      pdf.number_pages "Policy Holder Initials ______________", :at => [433, -20]
    end

    return true
  end

  def send_mail_about_new_price_quote(customer)
    begin
      Postoffice.template(' New Price Quote ', customer.email, {:customer => customer}).deliver
    rescue
    end
  end

  def notes_customer_ids
    self.notes.map(&:customer_id).map{|p| [p, p]}
  end

  def notes_claim_ids
    #self.notes.where("notable_type = ?",'Claim').map(&:notable_id).map{|p| [p,p]}
    self.claims.map(&:id).map{|p| [p,p]}
  end

  def customer_current_date_time
    return self.created_at.strftime("%m/%d/%Y - %H:%M %p")
  end

  def contract_link
    "https://#{$installation.www_domain}/admin/customers/edit/#{self.id}"
  end

  def package_type
    return self.package.package_name
  end

  def package_type_options
    return self.package.coverages.map(&:coverage_name).join(", ")
  end

  ## --------------------------------------------------

  protected
  
  def create_icontact_id(arg=nil) # occurs before_save
    return true
    
    unless self.icontact_id
      # Create a new iContact immediately
      response = IContactRequest.new({
        :path => 'contact',
        :put => self.to_icontact_record
      }).call
      if response.successful?
        self.icontact_id = response.xml.root.elements['result'].elements['contact'].attributes['id'].to_i
      end
    else
      # Queue a contact update
      IContactRequest.create({
        :path => "contact/#{self.icontact_id}",
        :put => self.to_icontact_record
      })
    end
    return true
  end
  
  def update_icontact_info(arg=nil) # occurs after_save
    return true
    
    return true unless self.icontact_id
    
    # login to iContact and update the information based on the current status
    case self.status_id
    when 1              # Left Message
      self.enqueue_follow_up_list_action(:remove)
      self.enqueue_left_message_list_action(:add)
    when 2              # Deleted
      self.enqueue_follow_up_list_action(:add)
      self.enqueue_left_message_list_action(:remove)
    when 3              # Follow up
      self.enqueue_follow_up_list_action(:add)
      self.enqueue_left_message_list_action(:remove)
    when 4              # Completed Order
      self.enqueue_follow_up_list_action(:add)
      self.enqueue_left_message_list_action(:remove)
    when 5              # Cancelled
      self.enqueue_follow_up_list_action(:remove)
      self.enqueue_left_message_list_action(:remove)
    when 6              # Proforma
      self.enqueue_follow_up_list_action(:add)
      self.enqueue_left_message_list_action(:remove)
    end
    
    return true
  end

  def add_referred_from_from_company
    if self.partner.present?
      self.from = "#{self.partner.company_name}: #{self.leadid}"
    end
  end  
end
