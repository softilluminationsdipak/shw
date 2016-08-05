require 'digest/sha1'

class Admin::AdminController < ApplicationController
  
  before_filter :check_login, :except => ['login', 'logout', 'authenticate']
  before_filter :check_permissions
  # ssl_exceptions []
  
  layout 'admin', :except => [:claim_dashboard3]
  
  def index ## Used for dashboard
   redirect_to "/admin/#{current_account.role}/dashboard"
  end

  def admin_dashboard ## Access by admin only
    redirect_to "/admin/dashboard"
  end
  
  def claims_dashboard ## Only for Claim Login
    redirect_to "/admin/claims/dashboard"
  end

  def retriction
    render :layout => 'admin_setting2'
  end

  def dashboard  ## Access by admin only  
    @page_title   = "Sales"
    @selected_tab = 'index'
    requrl        = request.url
    if current_account.admin?
      if requrl.scan(/admin/).size >= 2
        redirect_to "/admin/dashboard"
      else
        render :layout => 'new_admin'
      end
    else
      redirect_to '/admin/index'
    end
  end

  def login ## This action is used for login - Admin / Sales / Claim / Customer
    set_selected_tab
    respond_to do |format|
      format.html{ render :layout => $installation.code_name }
    end
  end
  
  def logout ## used for logout any user
    reset_session
    session[:account_id] = nil
    redirect_to '/'
  end
  
  def authenticate ## used for SignIn with Admin / Sales / Claim
    if params[:email].present?
      account_info = params[:email].match(/^shw1(\d+$)/i)
    else
      account_info = nil
    end

    if account_info.nil? then
      account = Account.find_by_email(params[:email])
    end

    logger.info("* Logging in #{params[:email]}")
    if account
      destination = '/admin'
      if account.customer?
        destination = "/admin/customers/edit/#{account.parent_id}"
      end
      destination = '/admin/repairs' if account.contractor?
      logger.info("* Destination will be #{destination}")
      
      if Digest::SHA1.hexdigest(params[:password]) == account.password_hash
        session[:account_id]    = account.id
        session[:timeout_after] = 30.minutes.from_now
        if account.customer?
          session[:account_id] = nil
          session[:timeout_after] = 1.minutes.from_now
        end        
        account.update_attributes({
          :last_login_ip => request.remote_ip,
          :last_login_at => Time.now
        })
        
        logger.info("* Login successful")
        redirect_to(destination)
        return
      else
        logger.info("* Incorrect Password")
        flash[:wrong_password] = true
        redirect_to(params[:url_from] || '/admin/login')
        return
      end
    else
      logger.info("* Incorrect Email")
      flash[:wrong_email] = true
      redirect_to(params[:url_from] || '/admin/login')
      return
    end
  end

  def null ## While getting null action it will redirect to root path
    redirect_to "/"
  end

  protected
  
  def set_selected_tab
    @selected_tab = :dashboard
  end
end
