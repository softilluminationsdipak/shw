class Discount < ActiveRecord::Base
  has_many :customers
  
  attr_accessible :is_monthly, :starts_at, :ends_at, :value, :name
  def code
    if self.is_monthly
      if self.starts_at.present? 
        "#{$installation.invoice_prefix}#{self.starts_at.strftime("%b").upcase}#{(self.value*100).to_i}"
      else
        "#{$installation.invoice_prefix}#{self.starts_at}#{(self.value*100).to_i}"
      end
    else
      self.name
    end
  end
  
  def amount
    return 0 unless self.value
    if self.value <= 1.0
      "#{(self.value*100).to_f.round(2)}%"
    else
      "$%4.2f" % self.value
    end
  end
  
  def is_percentage?
    self.value.present? && self.value <= 1.0
  end
  
  def is_valid?
    Time.now >= self.starts_at and Time.now <= (self.ends_at || Time.now)
  end
  
  def notification_summary
    "Discount #{self.code}"
  end
  
  def edit_url
    "/admin/discounts/edit/#{self.id}"
  end
end
