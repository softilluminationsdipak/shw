class ShwController < ApplicationController

  layout :installation_layout,:except => [:error]

  before_filter :internal_page, :except => [:plans, :error]

	def installation_layout
    $installation.code_name
  end

  def termsconditions
    @page_title = "Terms and Conditions"
  end

  def resourcecenter
    redirect_to '/versus'
  end

  def index
    unless request.format.to_s == 'text/html'
      redirect_to '/'
    end
    @without_padding = 'withoutPadding'
  end

  def versus
    @page_title = "Home Warranty vs. Homeowners Insurance"
  end

  def homeownercenter
    @page_title     = "Homeowner Center"
    @content_class  = "homeowners-page"
  end

  def plans
    @page_title         = "Coverage Plans"
    @optional_coverages = Coverage.where(:optional => true).collect(&:coverage_name).in_groups(3)
  end

  def realestate
    @page_title     = "Real Estate Professionals"
    @content_class  = "get-quote-page" # TODO: Rename to full-width
  end

  def contractors
    @page_title     = "Contractor Helpdesk"
    @content_class  = "get-quote-page" # TODO: Rename to full-width
  end

  def request_thankyou
  	@page_title = "Thank You!"
    name        = params[:request][:name]
    state       = params[:request][:state]
    phone       = params[:request][:phone]

    if verify_recaptcha && name.present? && state.present? && phone.present?
      Submitclaim.create(:name => params[:request][:name], :policy_number => params[:request][:policy_number], :issue_type => params[:request][:issue_type], :issue_description => params[:request][:description], :phone_number => params[:request][:phone], :email => params[:request][:email], :address => params[:request][:address], :city => params[:request][:city], :state => params[:request][:state], :zipcode => params[:request][:zip], :ip_address => request.remote_ip)
      #Postoffice.template(params[:template_name], ['dipak@softilluminations.com'], params[:request], current_account.email).deliver
    	Postoffice.template(params[:template_name], ['claims@selecthomewarranty.com'], params[:request], current_account.email).deliver
    else
      if params['pname'] == 'submitclaim'
        redirect_to "/submitclaim", :notice => "Captach is not valid!"
      elsif params['pname'] == 'contractors'
        redirect_to "/contractors", :notice => "Captach is not valid!"
      else
        redirect_to "/realestate", :notice => "Captach is not valid!"
      end
    end
  end

  def contact
    @page_title = "Contact Us"
  end

  def faq
    @page_title = "Frequently Asked Questions"
    @content    = Content.for(:faq).html_safe
  end
  alias :faqs :faq

  def testimonials
    @page_title = "Testimonials"
  end

  def api_doc
    if current_partner.present?
      render :layout => 'bootstraplayout2'
    else
      redirect_to root_path
    end
  end

  def lead_api_doc
    render :layout => 'bootstraplayout2'
  end

	def about
    @page_title = "About Us"
  end

  def error
    render :layout => "error"
  end

  def affiliate_portal
    render :layout => "api_doc_layout"
  end

  protected

  def internal_page
    @content_class = "internal-page"
  end

end
