class IpTrack < ActiveRecord::Base
  attr_accessible :remote_ip, :created_at, :updated_at, :source_format
  attr_accessible :browser_title, :os_title
  
  attr_accessible :country_code, :country_name, :city, :region_name, :zip_code
  attr_accessible :latitude, :longitude, :timezone

  before_create :analysis_ip_info
  
  belongs_to :customer
  
  def analysis_ip_info
		begin
		  response = GeoLocation.find(self.remote_ip)

		  self.country_code = response[:country_code]
		  self.country_name = response[:country]
		  self.city = response[:city]
		  self.region_name = response[:region]
		  self.latitude = response[:latitude].to_f
		  self.longitude = response[:longitude].to_f
		  self.timezone = response[:timezone]
		rescue
		end
  end
  
end
