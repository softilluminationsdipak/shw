class Renewal < ActiveRecord::Base
  belongs_to :customer

  scope :for_agent, lambda { |agent|
    #{ :joins => Renewal.agents_join_sql(agent.id) }
    joins("LEFT JOIN customers on renewals.customer_id = customers.id ").joins("LEFT JOIN agents on customers.agent_id = agents.id").where("agent_id = ? and customers.status_id = ?", agent.id ,4)
  }

  scope :for_agent_renewal_between, lambda { |agent, from, to|
  #  joins("LEFT JOIN customers on renewals.customer_id = customers.id").joins("LEFT JOIN agents on customers.agent_id = agents.id").where("agents.id = #{agent.id} and customers.status_id = 4 and renewals.customer_id IN (?)",Renewal.where("ends_at BETWEEN '#{from.strftime('%Y-%m-%d')}' AND '#{to.strftime('%Y-%m-%d')}'").map(&:customer_id).uniq.join(","))
    renewals = Renewal.where("ends_at BETWEEN '#{from.strftime('%Y-%m-%d')}' AND '#{to.strftime('%Y-%m-%d')}'")
    customer_ids = renewals.collect{|renewal| renewal.customer_id}.uniq
    customer_ids = customer_ids.join(",") # (83372) #
    
    join = Renewal.agents_join_sql(agent.id)
    join << " AND renewals.customer_id IN (#{customer_ids})" if customer_ids.present?
    { :joins => join }
  }


  def self.agents_join_sql(id)
    "LEFT JOIN customers ON renewals.customer_id = customers.id " <<
    "LEFT JOIN agents ON customers.agent_id = agents.id " <<
    "WHERE agents.id = #{id} and customers.status_id = 4"
  end

  def edit_url
  end
  
  def notification_summary
    "#{self.duration} Year Contract Renewal for #{self.customer.notification_summary}"
  end
  
  def as_json(a=nil,b=nil)
    {
      :id => self.id,
      :starts => self.starts,
      :ends => self.ends,
      :formatted_duration => self.formatted_duration,
      :formatted_amount => self.formatted_amount
    }
  end
  
  def formatted_amount
    "$%.2f" % self.amount.to_f
  end
  
  def starts
    self.starts_at.strftime('%m/%d/%Y') if self.starts_at
  end
  
  def ends
    self.ends_at.strftime('%m/%d/%Y') if self.ends_at
  end
  
  def formatted_duration
    "#{self.duration} Year#{'s' if self.duration > 1}"
  end
  
  def duration
    return 0 if (self.years.nil? || self.years == 0) && (self.ends_at.nil? || self.starts_at.nil?)
    (self.years || 0) > 0 ? self.years : (self.ends_at.jd - self.starts_at.jd).abs / 365
  end
end
