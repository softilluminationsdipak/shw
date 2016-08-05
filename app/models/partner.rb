class Partner < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  acts_as_paranoid
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :firstname, :lastname, :phone, :company_name, :auth_token, :company_api_access, :discount_code, :address1, :address2, :city, :state, :zipcode, :tracking_link
  # attr_accessible :title, :body
  attr_accessor :old_password
  #API_ACCESS = %w(Approved Denied Hold)  
  API_ACCESS = ["Approved", "Denied", "In Progress"]

  has_many :customers
  before_save :send_mail_for_api_access_info
  before_create :generate_unique_token_for_api
  #before_create :generate_discount_code2
  before_save :generate_discount_code
  has_many :auth_tokens, :dependent => :destroy
  has_many :sub_affiliates, :dependent => :destroy
  
  def generate_unique_token
    auth_token = SecureRandom.hex(20)
    unless Partner.find_by_auth_token(auth_token)
    	auth_token = SecureRandom.hex(20)
    end
    return auth_token
  end

  class << self
    def authenticate_company_login(email,password)
      return nil, "email and password can't blank" if !email.present? && !password.present?
      return nil, "email required" unless email.present?
      return nil, "password required" unless password.present?
      company = find_by_email(email)
      return nil, "There is no company registered" unless company.present?
      if company.valid_password?(password)
        return company,""
      else
        return company,"invalid password"
      end
    end
  end

  def is_access_approved?
    self.company_api_access == "Approved"
  end

  def is_access_denied?
    self.company_api_access == "Denied"
  end

  def is_access_hold?
    self.company_api_access == "In Progress"
  end

  def self.from_omniauth(auth)
    where(auth.slice(:provider, :uid)).first_or_initialize.tap do |partner|
      partner.provider = auth.provider
      partner.uid = auth.uid
      partner.email = auth.info.email      || ''
      partner.lastname = auth.info.last_name  || ''
      partner.firstname = (auth.provider == "twitter") ? auth["info"]["name"] : auth.info.first_name
      partner.oauth_token = auth.credentials.token || ''
      partner.oauth_expires_at = Time.at(auth.credentials.expires_at) if auth.provider == "facebook"
      partner.auth_token = partner.auth_token.present? ? partner.auth_token : ''
      partner.company_api_access = partner.company_api_access.present? ? partner.company_api_access : "In Progress"
      partner.save(:validate => false)
    end
  end

  def admin_url
    "https://#{$installation.www_domain}/admin/partners"
  end

  def fullname
    "#{self.firstname} #{self.lastname}" if self.firstname.present?  && self.lastname.present?
  end

  def partner_url
    "https://#{$installation.www_domain}/partners"
  end

  def login
    self.email
  end

  def api_token
    self.auth_token
  end

  def api_documentation
    "https://#{ENV['DOMAIN_CONFIG']}/api_doc"
  end

  def send_mail_for_api_access_info
    if self.company_api_access_changed?
      if self.is_access_approved?
        Postoffice.template('API Approval', self.email, {:partner => self}).deliver
      elsif self.is_access_denied?
        Postoffice.template('API Denial', self.email, {:partner => self}).deliver
      end
    end
  end

  def generate_unique_token_for_api
    token = self.generate_unique_token
    self.auth_token = token
    #self.auth_tokens.build(:auth_token => token)
  end

  def generate_discount_code2
    token = self.auth_token
    discount_code = token[0..5]
    self.discount_code = discount_code
    self.save
  end

  def generate_discount_code
    if self.auth_token
      token = self.auth_token
      discount_code = token[0..5]
      self.discount_code = discount_code
    end
  end

  def notification_summary
    "Partner/Affilate - ID #{self.id} & Name - #{self.fullname}"
  end
  
  def edit_url
    "/admin/partners/edit/#{self.id}"
  end

end
