class Ipaddress < ActiveRecord::Base
  attr_accessible :ip

  validates_presence_of :ip
  validates_uniqueness_of :ip

  def notification_summary
    "IP - #{self.ip}"
  end
  
  def edit_url
    "/admin/ipaddresses/edit/#{self.id}"
  end

end
