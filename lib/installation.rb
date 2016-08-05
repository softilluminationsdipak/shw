class Installation
  attr_reader :name, :short_name, :code_name, :domain, :www_domain, :phone, :fax, :invoice_prefix, :fax_service
  attr_reader :admin_email, :claims_email, :info_email, :noreply_email, :noreply_email_contact, :customercare_email
  attr_reader :ga_tracking_id, :ip_address
  attr_accessor :active_states, :ip_address
  
  attr_reader :credentials
  
  attr_accessor :auto_delivers_emails
  alias :auto_delivers_email :auto_delivers_emails
  
  def [](key)
    @credentials.has_key?(key) ? @credentials[key].symbolize_keys : nil
  end
  
  def initialize(name, short_name, code_name, domain, www_domain, phone, fax, invoice_prefix, fax_service, auto_delivers_emails=true, ga_tracking_id='', ip_address)
    @name           = name
    @short_name     = short_name
    @code_name      = code_name
    @domain         = domain
    @www_domain     = www_domain
    @phone          = phone
    @fax            = fax
    @invoice_prefix = invoice_prefix
    @fax_service    = fax_service.constantize
    
    @credentials    = {}
    
    @admin_email    = "admin@#{domain}"
    @claims_email   = "claims@#{domain}"
    @info_email     = "info@#{domain}"
    @noreply_email  = "info@#{domain}"
    @noreply_email_contact  = "contact@#{domain}"
    @customercare_email = "info@#{domain}"
    
    @auto_delivers_emails = auto_delivers_emails

    @ga_tracking_id = ga_tracking_id
    
    @active_states = []
    @ip_address = []
  end
  
  def add_credentials(service, data)
    return if @credentials.has_key?(service)
    @credentials[service.to_sym] = data
    return self
  end
  
  def self.default_email_templates
    {
      'Proforma'                  => ['Proforma Invoice {customer contract_number}', :tabular],
      'Welcome'                   => 'Welcome to {installation name}, {customer name}',
      'New Web Order'             => 'New Web Order, Customer {customer contract_number}',
      'Join Our Team'             => ['Request to Join {installation short_name}', :tabular],
      'Become Contractor'         => ['Request to become {installation short_name} Contractor', :tabular],
      'Billing'                   => ['{installation name}', :agent],
      'Renewal'                   => ['{installation name}', :agent],
      'New Claim by Customer'     => 'New Claim by Customer {customer contract_number}',
      'Welcome Contractor'        => 'Welcome to {installation name}',
      'Monthly'                   => ['Home Warranty Account', :agent],
      'Contractor Assigned'       => ['Contractor Assigned to {installation short_name} Claim {customer contract_number}', :agent],
      'Price Quote'               => ['Your Price Quote', :tabular],
      'Signed Contract Reminder'  => ['Signed Contract Reminder', :agent]
    }
  end
  
  def self.default_content
    %w(terms_of_service testimonials terms_and_conditions faq)
  end
  
  def self.load!
    if Rails.env.production?
      json = File.read("#{Rails.root}/config/installation.json")
    else
      json = File.read("#{Rails.root}/config/installation_test.json")
    end

    init = ActiveSupport::JSON.decode(json)
    $installation = Installation.new(*init['params'])
    $installation.active_states = init["active_states"]
    $installation.ip_address = init["ip_address"]
    init['credentials'].each { |name, data| $installation.add_credentials(name, data) }

    # init fax_source lock_flag
    #FaxSource.all.each do |source|
    #  source.lock_flag = 0
    #  source.save
    #end

  end
end
