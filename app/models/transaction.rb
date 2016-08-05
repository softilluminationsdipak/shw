class Transaction < ActiveRecord::Base

  attr_accessible :response_code, :response_reason_text, :auth_code, :amount, :subscription_paynum, :subscriptionid, :subscription_id, :sub_id, :payment_type, :transaction_id, :transactionid, :refund, :merchant_nickname, :gateway_id
  # transaction_id, customer_id, subscription_id, original_agent_id

  belongs_to :customer
  belongs_to :subscription, :foreign_key => 'sub_id'

  #belongs_to :agent, :foreign_key => 'original_agent_id'
  has_one :agent, :through => :customer

  scope :of_customer, lambda { |id| { :conditions => ['customer_id = ?', id ] } }
  scope :for_agent, lambda { |agent|
    #{ :joins => Transaction.agents_join_sql(agent.id) }
    joins("LEFT JOIN customers on transactions.customer_id = customers.id ").joins("LEFT JOIN agents on customers.agent_id = agents.id").where("agent_id = ? and customers.status_id = ?", agent.id ,4)
  }
  scope :for_agent_between, lambda { |agent, from, to|
    join = Transaction.agents_join_sql(agent.id)
    join << " AND transactions.created_at BETWEEN '#{from.strftime('%Y-%m-%d')}' AND '#{to.strftime('%Y-%m-%d')}'"
    { :joins => join }
  }
  scope :for_agent_renewal_between, lambda { |agent, from, to|

    joins("LEFT JOIN customers on transactions.customer_id = customers.id").joins("LEFT JOIN agents on customers.agent_id = agents.id").where("agents.id = #{agent.id} and customers.status_id = 4 and transactions.customer_id IN (?)",Renewal.where("ends_at BETWEEN '#{from.strftime('%Y-%m-%d')}' AND '#{to.strftime('%Y-%m-%d')}'").map(&:customer_id).uniq.join(","))
    #customer_id_array = Transaction.search_customer_by_renewal_date(agent, from,to)
    
    #join = Transaction.agents_join_sql(agent.id)
    #join << " AND transactions.customer_id IN (#{customer_id_array})"
    #{ :joins => join }
  }
  
  scope :approved, :conditions => { :response_code => 1 }
  attr_accessible :response_code, :response_reason_text, :auth_code, :amount, :transaction_id, :subscription_id, :subscription_paynum

  def Transaction.agents_join_sql(id)
    "LEFT JOIN `customers` ON transactions.customer_id = customers.id " <<
    "LEFT JOIN `agents` ON customers.agent_id = agents.id " <<
    "WHERE agents.id = #{id} and customers.status_id = 4"
  end

  
  def Transaction.search_customer_by_renewal_date(agent, from,to)
   # renewals = Renewal.where("ends_at BETWEEN '#{from.strftime('%Y-%m-%d')}' AND '#{to.strftime('%Y-%m-%d')}'")
   # customer_ids = renewals.collect{|renewal| renewal.customer_id}.uniq
   # customer_ids.join(",")
  end

  def edit_url
    '/admin/transactions'
  end

  def notification_summary
    self.dollar_amount
  end

  def result
    case self.response_code
    when 1
      "Approved"
    when 2, 4
      "Declined"
    when 6
      "Invalid Card"
    when 8
      "Expired Card"
    when 27
      "AVS Mismatch"
    when 11
      "Duplicate"
    when -1
      "Credit"
    when -2
      "Void"
    when -3
      "Voided"
    else
      ""
    end
  end

  def dollar_amount
    "$%.2f" % (self.amount || 0.0)
  end

  def result_class
    "transaction_#{self.result.downcase.gsub(/\s/, '')}"
  end

  def approved?
    self.response_code == 1
  end

  def tran_payment_type
    if self.payment_type.to_s.downcase == 'nmi'
      if self.subscriptionid.present?
        ptype = 'NMI Subscription'
      else
        ptype = 'NMI Manual'
      end
    else
      ptype = self.payment_type
    end
    return ptype
  end

  def gateway_mname
    if self.gateway_id.present?
      gateway = Gateway.find(self.gateway_id)
      gateway.merchant_name
    else
      ''
    end
  end
  protected

  def after_save
    if [2,4,6,8,27].include?(self.response_code) and self.customer
      Postoffice.template('Billing', [self.customer.email], { :customer => self.customer },current_account.email).deliver
    end
  end
end
