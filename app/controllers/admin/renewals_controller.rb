class Admin::RenewalsController < ApplicationController
  before_filter :check_login
  #before_filter :only_admin_access, :except => [:async_get_for_customer]
  before_filter :check_permissions

  ssl_exceptions []
  
  def async_get_for_customer ## Used in Sales /
    render :json => Customer.find(params[:id]).renewals, :layout => false
  end
  
  def async_create_for_customer
    # [FIXME]
    # ------------------------------------------------------------
    # temporary code, only input ends_at
    params[:renewal][:starts_at] = params[:renewal][:ends_at]
    # ------------------------------------------------------------
    
    params[:renewal][:customer_id] = params[:id]
    renewal = Renewal.new(params[:renewal])
    if params[:renewal][:ends_at].present? 
      renewal.ends_at = DateTime.strptime(params[:renewal][:ends_at], "%m/%d/%y")
      renewal.starts_at = DateTime.strptime(params[:renewal][:starts_at], "%m/%d/%y")
      renewal.save
      notify(Notification::CREATED, { :message => 'created', :subject => renewal })
    end
    render :json => renewal, :layout => false
  end
  
  def async_remove_for_customer
  begin
    Customer.find(params[:id]).renewals.order("created_at ASC").first.delete
  rescue
  
  end
    render :json => {:result => 0}
  end
  
end
