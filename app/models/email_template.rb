class EmailTemplate < ActiveRecord::Base
  
  attr_accessor :data

  attr_accessible :name, :subject, :body, :locked, :attachments, :reply_to, :from
  
  before_save :store_value_in_reply_to
  
  def store_value_in_reply_to
    unless self.reply_to.present?
      self.reply_to = self.from
    end
  end

  def edit_url
    "/admin/email_templates/edit/#{self.id}"
  end

  def is_contract_pdf_attachable?
    @contract_pdf_attach rescue false
  end
  def is_work_order_pdf_attachable?
    @workorder_pdf_attach rescue false
  end
  def is_performa_invoice_pdf_attachable?
    @performa_invoice_pdf_attach rescue false
  end

  def notification_summary
    "\"#{self.name}\" Template"
  end
  
  def parse_attachments
    self.parse(self.attachments)
  end

  def parsed_subject
    return self.parse(self.subject)
  end
  
  def parse(s)
		return s.gsub(/\{(.+?)\s(.+?)\}/) do |match|
			begin
				case $1
				when 'the'
					@data[$2.to_sym]
                                when 'login'
                                        if $2 == 'url' then
                                          'https://selecthomewarranty.com/login'
                                        end
				when 'installation'
				  $installation.send($2)
        when 'partner'
          if @data[:partner] then @data[:partner].send($2) end
				when 'customer'
					if @data[:customer] then @data[:customer].send($2) end
				when 'contractor'
				  if @data[:contractor] then @data[:contractor].send($2) end
				when 'my'
					if @data[:my] then @data[:my].parent.send($2) end
				when 'image'
					if $2 == 'logo'
					  '<a href="http://' + $installation.www_domain + '"><img src="http://' + $installation.www_domain + '/assets/logo.png" alt="' + $installation.name + '"/></a>'
          elsif $2 == 'logo2'
            '<a href="http://' + $installation.www_domain + '"><img src="http://' + $installation.www_domain + '/assets/logo.jpg" height="90" width="238" alt="' + $installation.name + '"/></a>'
					end
        when 'attach'
          if $2 == 'contract_pdf' then
            @contract_pdf_attach =true
            ""
          elsif $2 == 'workorder_pdf' then
            @workorder_pdf_attach =true
            ""
          elsif $2 == 'performa_invoice_pdf' then
            @performa_invoice_pdf_attach =true
            ""
          end
        when 'image_main'
          if $2 == 'logo'
            '<img src="https://' + $installation.www_domain + '/assets/image_main.jpg" height="245" width="600" border="0" alt="' + $installation.name + '"/>'
          end
				end
			rescue
				# Suppress Errors
			end
		end
  end
  
  def parsed_body
   return self.parse(self.body).html_safe
  end
  
  def EmailTemplate.placeholders
  	[
     # ['attach contract_pdf', 'Send contract pdf file as attachment'],
     # ['attach workorder_pdf', 'Send workorder pdf file as attachment'],
     # ['attach performa_invoice_pdf', 'Send performa invoice pdf file as attachment'],
     # ['attach buyoutrelease_pdf', 'Send BuyOut/Release pdf file as attachment'],

  		['image logo', 'Logo and Slogan with link to site'],
  		['customer first_name', 'John'],

      ['partner fullname', 'John Smith'],
      ['partner partner_url', "https://#{$installation.www_domain}/partners"],
      ['partner login', 'johnsmith@fake.com'],
      ['partner password', 'xxxxx'],
      ['partner api_token', '24be6a603f73cceccbe02053b65aeb9d795106f0'],
      ['partner api_documentation', '/api-doc'],
  		['customer last_name', 'Smith'],
  		['customer name', 'John Smith'],
  		['customer contract_number',  "##{$installation.invoice_prefix}000321"],
  		['customer _contract_number', "#{$installation.invoice_prefix}000321"],
  		['customer contract_url', "https://#{$installation.www_domain}/contract/#{$installation.invoice_prefix}000321"],
  		['customer email', 'johnsmith@fake.com'],
  		['customer full_address', '123 Maple St., Springfield, VA, 12345'],
  		['customer address', '123 Maple St.'],
  		['customer city', 'Springfield'],
  		['customer state', 'VA'],
  		['customer zip_code', '12345'],
  		['customer package_name', 'Full System'],
  		['customer pay_amount', 'Amount Per Payment'],
  		['customer package_price', '399.99'],
  		['customer list_price', 'Pkg. Price + Cvg. Addons'],
  		['customer coverage_option_names', 'Pool/Spa, Septic System'],
  		['customer payment_schedule', '4 Monthly Payment(s)'],
  		['customer service_fee', '$60 (Sixty Dollars)'],
  		['contractor name', 'Joe Schmoe'],
  		['contractor company', 'Joe Schmoe Contracting'],
      ['login url', "#{ENV['DOMAIN_CONFIG']}/login"],
      ['installation phone', $installation.phone],
      ['installation fax', $installation.fax],
  	]
  end
end
