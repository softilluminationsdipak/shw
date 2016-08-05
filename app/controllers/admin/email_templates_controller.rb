class Admin::EmailTemplatesController < ApplicationController
  before_filter :check_login
  before_filter :redirect_to_customer_page
  before_filter :check_permissions

  #layout 'new_admin'
  layout 'admin_settings'
  protect_from_forgery :except => [:async_quickly_email, :async_quickly_email_with_js]

  ssl_exceptions []

  def index
    add_breadcrumb "Email Templates"

    @selected_tab = 'content'
    @page_title = "Email Templates"
    @templates = EmailTemplate.find :all
  end
  
  def edit
    add_breadcrumb "Email Templates", "/admin/email_templates"
    add_breadcrumb "Edit"
    
    @selected_tab = 'content'
    @email_template = EmailTemplate.find params[:id]
    @page_title = "Email Templates - #{@email_template.name}"
  end
  
  def create
    et = EmailTemplate.create(params[:email_template])
    notify(Notification::CREATED, et)
    
    redirect_to :action => 'index'
  end
  
  def update
    et = EmailTemplate.find(params[:id])
    updated = et.update_attributes(params[:email_template])
    notify(Notification::UPDATED, et) if updated
    
    redirect_to :action => 'index'
  end
  
  def destroy
    et = EmailTemplate.find(params[:id])
    notify(Notification::DELETED, et)
    et.destroy
    
    redirect_to :action => 'index'
  end

  def async_quickly_email
      if request.get?
  	  templates = {}
  	  EmailTemplate.find(:all, :order => 'name ASC').each { |t| templates[t.name] = t.id }
          render :json => templates
      else
      
       begin
        customer = Customer.find params[:customer_id]
        et = EmailTemplate.find(params[:template_id])
        
        email_opts = {:customer => customer, :my => current_account}
        if et.name == "Welcome Contractor" # Some extra context required
          email_opts[:attachments] = { 0 => {
            :path => 'app/views/admin/content',
            :filename => 'Contractor_Welcome2.pdf',
            :content_type => 'application/pdf'
          }}
          email_opts[:contractor] = customer
        end
        Postoffice.template(params[:template_id], customer.email, email_opts,current_account.email).deliver
        notify(Notification::INFO, { :message => "emailed #{et.notification_summary}", :subject => customer })
        render :json => { :result => :sent }
        return
       rescue
        logger.info("\n\nERROR: #{$!}\n\n")
        logger.info($!.backtrace)
        render :json => { :result => $!.message }
        return
       end
     end
  end

  def async_quickly_email_with_js
    if request.get?
      templates = {}
      EmailTemplate.find(:all, :order => 'name ASC').each { |t| templates[t.name] = t.id }
          render :json => templates
      else
      
       begin

        customer = Customer.find params[:customer_id] if params[:customer_id].present?
        contractor = Contractor.find(params[:contractor_id]) if params[:contractor_id].present?
        et = EmailTemplate.find(params[:template_id])
        
        if params[:customer_id].present?
          email_opts = {:customer => customer, :my => current_account}
        end
        if params[:contractor_id].present?
          email_opts = {:contractor => contractor, :my => current_account}
        end

        if et.name == "Welcome Contractor" # Some extra context required
          email_opts[:attachments] = { 0 => {
            :path => 'app/views/admin/content',
            :filename => 'Contractor_Welcome2.pdf',
            :content_type => 'application/pdf'
          }}
          email_opts[:contractor] = customer if params[:customer_id].present?
          email_opts[:contractor] = contractor if params[:contractor_id].present?
        end
        if params[:customer_id].present?
          Postoffice.template(params[:template_id], customer.email, email_opts,current_account.email).deliver
          notify(Notification::INFO, { :message => "emailed #{et.notification_summary}", :subject => customer })
        end
        if params[:contractor_id].present?        
          Postoffice.template(params[:template_id], contractor.email, email_opts,current_account.email).deliver
          notify(Notification::INFO, { :message => "emailed #{et.notification_summary}", :subject => contractor })
        end
        respond_to do |format|
          format.html{redirect_to root_path}
          format.js{}
        end
       rescue
        logger.info("\n\nERROR: #{$!}\n\n")
        logger.info($!.backtrace)
        respond_to do |format|
          format.html{redirect_to root_path}
          format.js{}
        end          
      end
    end
  end
end
