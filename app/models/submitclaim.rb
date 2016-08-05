class Submitclaim < ActiveRecord::Base
  attr_accessible :address, :city, :email, :ip_address, :issue_description, :issue_type, :name, :phone_number, :policy_number, :state, :zipcode
	def self.search(search, params)
	  if search
	    find(:all, :conditions => ['address LIKE ? or city LIKE ? or email LIKE ? or issue_type LIKE ? or name LIKE ? or policy_number LIKE ? or state LIKE ? or zipcode LIKE ?', "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%"]).paginate(:page => params[:page], :per_page => 50)
	  else
	    find(:all).paginate(:page => params[:page], :per_page => 50)
	  end
	end
end
