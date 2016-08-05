require 'net/https'
require 'rexml/document'

class Address < ActiveRecord::Base
  acts_as_mappable :auto_geocode => false

  # polymorphic relationship
  attr_accessible :address, :address2, :address3, :city, :state, :zip_code, :country, :lat, :lng, :verified_address, :geocoded_address

  belongs_to                    :addressable,       :polymorphic => true
  
  attr_accessor :should_skip_verification_and_geocoding
  before_save :create_geocode
    
  scope :of_contractors_with_zip_code, lambda { |z|
    { :conditions => { :zip_code => z, :addressable_type => 'Contractor' } }
  }
  
  scope :find_valid_properties, where("addresses.address IS NOT NULL && addresses.city IS NOT NULL && addresses.zip_code IS NOT NULL")

  def self.bad_address_for(record)
    Address.new({
      :address => "Bad address for invalid #{record.class.to_s} ##{record.id}",
      :city => 'Nowhere', :state => 'KS', :zip_code => '00000',
      :lat => 0.0, :lng => 0.0,
      :addressable_type => record.class.to_s, :addressable_id => record.id
    })
  end
  
  def to_s_for_contract
    "#{self.address}\n#{self.city_state_zip}\n\n".upcase
  end
  
  def duplicate_for_addressable!(object)
    attrs = self.attributes.dup
    attrs.delete(:id)
    attrs[:addressable_type]  = object.class.to_s
    attrs[:addressable_id]    = object.id
    new_address = Address.create(attrs)
  end
  
  def edit_url
    self.addressable.edit_url
  end
  
  def notification_summary
    # "#{self.addressable_type} #{self.address_type} Address #{self.short_form}"
    "#{self.addressable_type} #{self.address_type} Address"
  end
  
  def city_state_zip
    return [self.city, self.state].join(", ") << " " << self.zip_code
  end
  
  def to_s
    [self.address, self.address2, self.address3, self.city_state_zip].join(" ")
  end
  
  def to_hash
    {
      :id => self.id,
      :string => self.to_s,
      :address => self.address,
      :address2 => self.address2,
      :address3 => self.address3,
      :city => self.city,
      :state => self.state,
      :zip_code => self.zip_code,
      :address_type => self.address_type,
      :verified => self.verified?,
      :lat => self.lat,
      :lng => self.lng,
      :geocoded => self.geocoded?
    }
  end
  
  def as_json(one=nil, two=nil)
    self.to_hash
  end
  
  def geocode
    return if @should_skip_verification_and_geocoding
    begin
      geo = nil
      Timeout::timeout(5) {
        geo = Geokit::Geocoders::MultiGeocoder.geocode(self.to_s)
      }
      if geo.success
        self.lat, self.lng = geo.lat,geo.lng
        self.geocoded_address = self.to_s
      end
    rescue Timeout::Error
      self.remove_geocode
    rescue
      self.remove_geocode
      raise unless Rails.env.production?
    end
  end
  
  def self.ups_request(request)
    https = Net::HTTP.new($AVS_URL.host, $AVS_URL.port)
    https.use_ssl = true;
    #https.verify_mode = OpenSSL::SSL::VERIFY_NONE
    https.verify_mode = OpenSSL::SSL::VERIFY_PEER
    xml = REXML::Document.new
    response_body = ''
    begin
      Timeout::timeout(5) {
        https.request_post($AVS_URL.path, request) { |response|
          response_body = response.class == Net::HTTPOK ? response.body : $AVS_FAILURE_RESPONSE
        }
      }
    rescue
      puts $!
      response_body = $AVS_FAILURE_RESPONSE
    ensure
      puts response_body
      xml = REXML::Document.new(response_body)
      error_code = xml.root.elements['Response'].elements['ResponseStatusCode'].text.to_i
      return xml, error_code
    end
  end
  
  def remove_geocode
    self.lat = nil
    self.lng = nil
    self.geocoded_address = nil
  end
  
  def geocoded?
    self.lat && self.lng && self.geocoded_address == self.to_s
  end
  alias geocoded geocoded?
  
  def verified=(is_verified)
    self.verified_address = is_verified ? self.to_s : nil
  end
  
  def verified?
    self.verified_address == self.to_s
  end
  alias verified verified?
  
  def verify
    return if @should_skip_verification_and_geocoding
    
    request = <<-XML
    #{$AVS_ACCESS_REQUEST}
    <AddressValidationRequest xml:lang="en-US"> 
      <Request> 
        <TransactionReference> 
          <CustomerContext>#{self.id}</CustomerContext> 
          <XpciVersion>1.0001</XpciVersion> 
        </TransactionReference> 
        <RequestAction>AV</RequestAction> 
      </Request> 
      <Address>
    XML
    if self.city and not self.city.empty? then request << "<City>#{self.city}</City>" end
    if self.state and not self.state.empty? then request << "<StateProvinceCode>#{self.state}</StateProvinceCode>" end
    if self.zip_code and not self.zip_code.empty? then request << "<PostalCode>#{self.zip_code}</PostalCode>" end
    request << "</Address></AddressValidationRequest>"
    xml, error_code = self.class.ups_request(request)
    if error_code == 1
      # Only accept the first result, and it has to be an exact match
      result = XPath.first(xml, '//AddressValidationResult')
      self.verified = result.elements['Quality'].text.to_f == 1.0
    end
  end
  
  def lat_lng
    LngLat.new(self.lng, self.lat) if self.geocoded?
  end
  
  def distance_to(dest)
    return self.lat_lng.mi_distance_to(dest) if self.geocoded? 
  end
  
  protected
  
  def create_geocode
    begin
      self.geocode unless self.geocoded?
    rescue
      #logger.info("Could not geocode Address ##{self.id} because: #{$!}")
      self.remove_geocode
    end
    return true
  end
end
