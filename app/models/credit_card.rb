require 'rubygems'
require 'authorize_net'

class CreditCard < ActiveRecord::Base
  belongs_to :customer
  belongs_to :address
  
  validates_presence_of :first_name, :last_name
  #validates_format_of :number, :with => /^\d{13,18}$/
  #validates_format_of :cvc, :with => /^\d+$/
  #validates_numericality_of :month, :only_integer => true
  #validates_numericality_of :year, :only_integer => true
  
  attr_accessor :cvc
  attr_encrypted :number, :key => 'key', :attribute => 'crypted_number'
  attr_accessible :last_4, :first_name, :last_name, :phone, :address_id, :exp_date, :number, :credit_card_number, :cvv


  def cc_with_last_4
    "***********#{self.try(:last_4)}"
  end

  def exp_date=(string)
    to_year = Proc.new { |s| s.to_s.length == 2 ? s.to_i + 2000 : s.to_i }
    self.month = 1
    self.year  = 2099
    if string =~ /^(\d{4})[\/-](\d{1,2})/
      self.month = $2.to_i
      self.year  = to_year[$1]
    elsif string =~ /^(\d{1,2})[\/-](\d{4})/
      self.month = $1.to_i
      self.year  = to_year[$2]
    elsif string =~ /^(\d{1,2})\/?-?(\d{2,4})/
      self.month = $1.to_i
      self.year  = to_year[$2]
    end
  end
  
  def exp_date
    "#{self.month}/#{self.year}"
  end

def charge_cents!(cents)
    state = State.find_by_name(self.customer.state)
    if state.present? && state.gateway_id.present?
      gateway = state.gateway
      self.customer.update_attributes(:merchant_name => gateway.merchant_name.present? ? gateway.merchant_name : '', :gateway_id => gateway.id)
      authorize = {:login=> gateway.login_id.strip, :password=> gateway.transaction_key.strip }
    else
      gateway = Gateway.default_gateway
      if gateway.present?
        self.customer.update_attributes(:merchant_name => gateway.merchant_name.present? ? gateway.merchant_name : '', :gateway_id => gateway.id)
        authorize = {:login=> gateway.login_id.strip, :password=> gateway.transaction_key.strip }
      else
        authorize = nil
      end
    end
    if authorize.present?
      begin
        gateway = ActiveMerchant::Billing::AuthorizeNetGateway.new(authorize)
        response = nil
      
        Timeout::timeout(120.seconds) {
          response = gateway.purchase(cents, self.to_am_creditcard, {
            :order_id      => self.customer.contract_number[1..-1],
            :cust_id       => self.customer.contract_number[1..-1]
          }.merge(self.am_billing_address_hash))
        }        
        return response
      rescue
        return response = nil
      end
    else
      return response = nil
    end
  end
=begin  
  def charge_cents!(cents)
    begin
      #gateway = ActiveMerchant::Billing::AuthorizeNetGateway.new($installation[:authorize])
      state = State.find_by_name(self.customer.state)
      if state.present? && state.gateway_id.present?
        gateway = state.gateway
        authorize = {:login=> gateway.login_id, :password=> gateway.transaction_key }
      else
        gateway = Gateway.default_gateway
        if gateway.present?
          authorize = {:login=> gateway.login_id, :password=> gateway.transaction_key }
        else
          authorize = nil
        end
      end
      if authorize.present?
        transaction = ActiveMerchant::Billing::AuthorizeNetGateway.new(authorize)
        #transaction = AuthorizeNet::AIM::Transaction.new(authorize[:login], authorize[:password], :gateway => :sandbox)
        response = nil      
        Timeout::timeout(120.seconds) {
          credit_card = AuthorizeNet::CreditCard.new(self.number, self.exp_date)
          response = transaction.purchase(cents/100, credit_card,{
            :order_id => self.customer.contract_number[1..-1],
            :cust_id       => self.customer.contract_number[1..-1]
          }.merge(self.am_billing_address_hash))
          if response.success?
            puts "Successfully made a purchase (authorization code: #{response.authorization_code})"
          else
            raise "Failed to make purchase."
          end
         }
        return response
      else
        response = nil
        return response
      end
    rescue
      return response = nil
    end
  end
=end
  def charge_cents2!(cents, params=nil)
    gw = GwApi.new()
    #gw.setLogin("powerpayhomewarranty", "MOANDJOEY123")
    gateway = Gateway.first
    merchant_account = Subscription.nmi_login(self.customer.state)
    if merchant_account.present?
      # gw.setLogin(merchant_account.username, merchant_account.password);
      gw.setLogin(gateway.login_id, gateway.password)
      @customer = self.customer
      gw.setBilling(@customer.first_name,@customer.last_name,"",@customer.address,@customer.address, @customer.city,@customer.state,@customer.zip_code,"US",@customer.customer_phone,@customer.work_phone,@customer.email,"")
      start_date = params[:start_date].present? ? params[:start_date].to_date : Time.zone.now.to_date
      end_date = params[:end_date].present? ? params[:end_date].to_date : ''
      if params[:occurances].present?
        end_date = "#{params[:start_date].to_date + params[:occurances].to_i.month}"
      end
      puts "=========merchant_account==========#{merchant_account.inspect}======"
      gw.setBilling(self.first_name, self.last_name, '', self.address.address, '', self.address.city, self.address.state, self.address.zip_code, self.address.country, self.phone, '', self.customer.email, '')
      r = gw.doSale2(cents.to_f/100,self.number,"#{self.month}/#{self.year}",'999', @customer, start_date, end_date, merchant_account)
      myResponses = gw.getResponses
      if (myResponses['response'] == '1')
        puts "Approved \n"
        status = "Approved"
      elsif (myResponses['response'] == '2')
        puts "Declined \n"
        status = "Declined"
      elsif (myResponses['response'] == '3')
        puts "Error \n"
        status = "Error"
      end
      subscription = Subscription.new({
        :credit_card_id => self.id,
        :start_date => params[:start_date].present? ? params[:start_date].to_date : '',
        :end_date => params[:end_date].present? ? params[:end_date].to_date : '',
        :amount => cents.to_f/100,
        :status => status,
        :customer_id => @customer.id,
        :occurances => nil,
        :interval => params[:interval].present? ? params[:interval] : '',
        :period => params[:period].present? ? params[:period] : '',
        :no_end_date => params['no_end_date'].to_s == 'true' ? true : false
      })
      subscription.save
      if subscription.start_date.to_date == Time.zone.now.to_date
        transaction = Transaction.new({
          :response_code => myResponses['response'],
          :response_reason_text => myResponses['responsetext'].present? ? myResponses['responsetext'] : 'Error' ,
          :auth_code => myResponses['authcode'],
          :amount => cents.to_f/100,
          :transactionid => myResponses['transactionid'],
          :subscriptionid => myResponses['subscription_id']
        })      
        transaction.customer_id = @customer.id
        transaction.subscription_id = transaction.subscriptionid
        transaction.transaction_id = transaction.transaction_id
        transaction.sub_id = subscription.id
        transaction.original_agent_id = @customer.agent_id if @customer and @customer.agent_id 
        transaction.payment_type = 'NMI'
        transaction.save
      end
    else
      myResponses = {'response' => 0, 'responsetext' => 'Invalid Merchant Account', 'authcode' => '000'}
    end
    return myResponses
  end  

  def charge_cents3!(cents, params=nil)
    gw = GwApi.new()
    gateway = Gateway.first
    merchant_account = Subscription.nmi_login(self.customer.state)
    puts "=========merchant_account==========#{merchant_account.inspect}======"
    if merchant_account.present?
      gw.setLogin(gateway.login_id, gateway.password)
      @customer = self.customer
      gw.setBilling(@customer.first_name,@customer.last_name,"",@customer.address,@customer.address, @customer.city,@customer.state,@customer.zip_code,"US",@customer.customer_phone,@customer.work_phone,@customer.email,"")
      start_date = params[:start_date].present? ? params[:start_date].to_date : ''
      gw.setBilling(self.first_name, self.last_name, '', self.address.address, '', self.address.city, self.address.state, self.address.zip_code, self.address.country, self.phone, '', self.customer.email, '')
      r = gw.doSale(cents.to_f/100,self.number,"#{self.month}/#{self.year}",'999',merchant_account)
      myResponses = gw.getResponses
      if (myResponses['response'] == '1')
        puts "Approved \n"
        status = "Approved"
      elsif (myResponses['response'] == '2')
        puts "Declined \n"
        status = "Declined"
      elsif (myResponses['response'] == '3')
        puts "Error \n"
        status = "Error"
      end
      transaction = Transaction.new({
        :response_code => myResponses['response'],
        :response_reason_text => myResponses['responsetext'].present? ? myResponses['responsetext'] : 'Error' ,
        :auth_code => myResponses['authcode'],
        :amount => cents.to_f/100,
        :transactionid => myResponses['transactionid'],
        :subscriptionid => myResponses['subscription_id']
      })      
      transaction.customer_id = @customer.id
      transaction.subscription_id = transaction.subscriptionid
      transaction.transaction_id = transaction.transaction_id
      transaction.original_agent_id = @customer.agent_id if @customer and @customer.agent_id 
      transaction.payment_type = 'NMI'
      transaction.save
    else
      myResponses = {'response' => 0, 'responsetext' => 'Invalid Merchant Account', 'authcode' => '000'}
    end
    return myResponses
  end  

  #def number
    #return '' if not self.crypted_number
    #cipher = Crypt::Rijndael.new(self.key)
    #@number = cipher.decrypt_string(Base64.decode64(self.crypted_number))
    #return @number
  #end
  
  #def number=(new_number)
    #return if new_number.nil? or new_number.empty?
    #@number = new_number
    #self.last_4 = new_number[-4..-1]
    #cipher = Crypt::Rijndael.new(self.key)
    #self.crypted_number = Base64.encode64(cipher.encrypt_string(new_number))
  #end
  
  def to_am_creditcard
    ActiveMerchant::Billing::CreditCard.new({
      :number   => self.number,
      :month    => self.month,
      :year     => self.year,
      :first_name => self.first_name,
      :last_name  => self.last_name#,
      #:verification_value => self.cvc
    })
  end
  
  def am_billing_address_hash
    {:billing_address => self.to_hash }
  end
  
  def to_hash
    {
      :first_name => self.try(:first_name),
      :last_name  => self.try(:last_name),
      :address1   => self.address.try(:address),
      :city       => self.address.try(:city),
      :state      => self.address.try(:state),
      :zip        => self.address.try(:zip_code),
      :country    => "US",
      :phone      => self.try(:phone)
    }
  end
  
  def as_json(a=nil,b=nil,is_admin=false)
    card_number = ""
      if is_admin
        begin
          card_number = self.try(:number)
        rescue
        end
      else
        begin
          if self.last_4.present?
            card_number = "***********#{self.try(:last_4)}"
          else
            card_number = nil
          end
        rescue
        end
      end
    self.attributes.dup.merge(self.to_hash).merge({
      :exp_date => self.try(:exp_date),
      :name => "#{first_name} #{last_name}",
      :address => self.address.try(:to_s),
      :number => card_number,
      :cvv => self.cvv
    })
  end
  
  protected
  
  def key
    Digest::SHA1.hexdigest(self.last_4)[0...16]
  end
end
