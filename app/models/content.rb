class Content < ActiveRecord::Base

  attr_accessible :slug, :html, :is_tos, :is_delete
  
  self.table_name = 'content'

  scope :only_tos, where('is_tos = ?', true)
  scope :only_deleted, where('is_delete = ?', true)
  scope :active_content, where('is_delete = ?', false)

  def self.for(slug)
    c = Content.find_by_slug(slug.to_s)
    c ? Content.replace_placeholders(c.html).html_safe : "No such slug - #{slug}"
  end

  def self.for_navigation_step(step_num=nil)
    if step_num
      text_with_commas = Content.for(:quote_wizard)
      text = text_with_commas.split(',') if text_with_commas
    end
      text[step_num-1] || 'Text Not Available' 
  end

    def self.replace_placeholders(content)
    placeholders = {
      'INSTALLATION_INFO_EMAIL' => $installation.info_email,
      'INSTALLATION_FAX_NUMBER' => $installation.fax,
      'INSTALLATION_NAME' => $installation.name,
      'INSTALLATION_PHONE' => $installation.phone,
      'INSTALLATION_CLAIMS_EMAIL' => $installation.claims_email
     
    }

    placeholders.each do |p|
      content.gsub!(escaped_placeholder_tag(p.first), p.last)
    end
    content
  end

  def self.escaped_placeholder_tag(string)
    delimiter = '|||'
    "#{delimiter}#{string}#{delimiter}"
  end

  def self.tos_for(customer)
    content = Content.for(:terms_of_service)
    placeholders = %w[ WAIT_PERIOD_TEXT_OVERRIDE! WAIT_PERIOD_DAYS_OVERRIDE! SERVICE_FEE_AMT_OVERRIDE! SERVICE_FEE_TEXT_OVERRIDE!]
    placeholders.each do |p|
      content.gsub!(escaped_placeholder_tag(p), customer.send(p.downcase.to_sym).to_s )
    end
    content
  end

  def self.tos_for2(customer)
    name    = customer.state_wise_tos.slug
    content = Content.for(name.to_sym)
    unless content.present?
      content = Content.for(:terms_of_service)
    end
    placeholders = %w[ WAIT_PERIOD_TEXT_OVERRIDE! WAIT_PERIOD_DAYS_OVERRIDE! SERVICE_FEE_AMT_OVERRIDE! SERVICE_FEE_TEXT_OVERRIDE!]
    placeholders.each do |p|
      content.gsub!(escaped_placeholder_tag(p), customer.send(p.downcase.to_sym).to_s )
    end
    content
  end

  #def self.tos_for_dupl(customer,state)
  #  content = Content.find(state).html
  #  content
  #end

  def notification_summary
    "Content For - #{self.slug}"
  end
  
  def edit_url
    "/admin/content/edit/#{self.id}"
  end

end
