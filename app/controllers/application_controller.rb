class ApplicationController < ActionController::Base
  require 'csv'
  require 'mac-address'
  require 'macaddr'

  protect_from_forgery
  
  #helper_method :current_partner
  alias_method :devise_current_partner, :current_partner
  include ::SslRequirement

  FOUR_OH_FOUR_EXCEPTIONS = [ActionController::UnknownAction, ActionController::RoutingError]
  IGNORABLE_EXCEPTIONS    = [ActionController::InvalidAuthenticityToken, ActionController::RoutingError, Net::SMTPFatalError]

  add_breadcrumb "Home", "/admin/admin_dashboard"
  
  def current_account
    session[:account_id].nil? ? Account.empty_account : Account.find(session[:account_id])
  end
  
  def with_timezone(time)
    if time.nil? then return "" end
  	time + current_account.timezone.hours + (time.isdst ? 1.hours : 0.hour)
  end
  
  #
  # retrieve the per_page request parameter or use a default value if request parameter not found
  #
  def get_per_page(params, default = 20)
    (params[:per_page]) ? params[:per_page].to_i : default
  end
  
  def rescue_action_in_public(exception)
    if FOUR_OH_FOUR_EXCEPTIONS.include?(exception.class)
      #Postoffice.message_(
      #  [$installation.admin_email],
      #  'Page Not Found',
      #  "The following page was errantly accessed:",
      #  "http://www.nationwidehomewarranty.com/#{params[:controller] != 'site' ? params[:controller] + '/' : ''}#{params[:action]}"
      #).deliver unless IGNORABLE_EXCEPTIONS.include?(exception.class)
      render :file => "#{Rails.root}/public/404.html", :layout => $installation.code_name, :status => 404
      return
    end
  end

  def local_request?
    false
  end
  
  def notify(type, options)
    Notification.notify(type, options, current_account)
  end

  def current_ability
    @current_ability ||= Ability.new(current_account)
  end
  
  protected

  def after_sign_in_path_for(resource)
    if current_partner.present? 
      affiliates_path
    else
      root_path
    end       
  end

  def check_login
    @current_account = current_account
    if @current_account.empty? or Time.now > (session[:timeout_after] || 1.second.ago)
      session[:account_id] = nil
      redirect_to '/admin/login'
    else
      session[:last_customers_async_list_page] ||= {}
      session[:timeout_after] = 30.minutes.from_now
    end
  end

  def check_permissions
    #controller_name = params[:controller].to_s
    #action_name     = params[:action].to_s
    #permission      = Permission.where('module_name = ? && action_name = ?', controller_name, action_name).try(:last)
    #if current_account.present?
      # if permission.present? #&& (Ipaddress.all.map(&:ip).include?(request.remote_ip.to_s))
      #   if current_account.admin? && permission.is_admin_access? && (Ipaddress.all.map(&:ip).include?(request.remote_ip.to_s)) 
      #    ## access by admin
      #   elsif current_account.sales? && permission.is_sales_access? && (Ipaddress.all.map(&:ip).include?(request.remote_ip.to_s)) 
      #     ## access by sales
      #   elsif current_account.claims? && permission.is_claim_access? && (Ipaddress.all.map(&:ip).include?(request.remote_ip.to_s)) 
      #     ## access by claims
      #   else
      #     #redirect_to "/admin/#{current_account.role}/dashboard"
      #     redirect_to "/admin/retricted"
      #   end
      # else
      #   #if current_account.admin?
      #     session[:account_id] = nil
      #     redirect_to '/admin/login'
      #   #else
      #   #  redirect_to "/admin/#{current_account.role}/dashboard"
      #   #end
      # end
    #end
  end

  def redirect_to_customer_page
    if current_account.role == "customer"
      redirect_to "/admin/customers/claims"
    end
  end

  def authenticate_partner
    unless current_partner.present?
      redirect_to new_partner_session_path
    end
  end
  
  private

  def current_partner
    if session[:partner_id].present?
      Partner.find(session[:partner_id])
    elsif params[:partner_id].blank?
      devise_current_partner
    else
      Partner.find(params[:partner_id])
    end
  end
  
end
