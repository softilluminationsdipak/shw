class CancellationReason < ActiveRecord::Base

  attr_accessible :reason
  has_many :customers
  
  def edit_url
    '/admin/content'
  end
  
  def notification_summary
    s = self.reason || ''
    if not s.empty?
      s = '(' + s[0...20]
      s << '...' if self.reason.length > 20
      s << ')'
    end
    "Cancellation Reason #{s}"
  end
  
  def as_json(one=nil, two=nil)
    {
      :id => self.id,
      :reason => self.reason
    }
  end
end
