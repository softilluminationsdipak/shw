class Note < ActiveRecord::Base
  belongs_to :customer
  belongs_to :notable, :polymorphic => true
  has_many :attachments, :as => :attachable

  ##after_save :update_note_text

  attr_accessible :note_text, :timestamp, :agent_name, :customer_id, :repair_id, :author_id

  def date
    self.created_at || (Time.at(self.timestamp).utc if timestamp)
  end
  
  def text
    (self.note_text || '').gsub(/\n/, '<br>')
  end
  
  def notification_summary
    s = self.note_text || ''
    if not s.empty?
      s = '(' + s[0...20]
      s << '...' if self.note_text.length > 20
      s << ')'
    end
    "Note for #{self.customer.notification_summary} #{s}"
  end
  
  def edit_url
    self.customer.edit_url
  end
  
  def note_type
    if self.notable_type.to_s == "Claim"
      return "Claim"
    else
      return "Customer"
    end
  end

  def note_reference
    if self.notable_type.to_s == "Claim"
      return "CLAIM: #{self.notable_id}"
    else
      return "CUSTOMER: #{self.customer_id}"
    end
  end

  def as_json(a=nil,b=nil)
    {
      :id => self.id,
      :date => self.date.in_time_zone(EST).strftime("%m/%d/%y %I:%M %p"),
      :text => self.text,
      :agent_name => self.agent_name,
      :ntype => self.note_type,
      :nref => self.note_reference
    }
  end

  #def update_note_text
  #  puts("=======#{self.note_text.split(" ").size.to_i}============================")
  #  if self.note_text.split(" ").size.to_i == 1
  #    self.note_text = self.note_text.scan(/.{1,100}/m).join(" ")
  #    self.save
  #  end
  #end

end
