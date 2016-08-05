class Admin::CancellationReasonsController < ApplicationController
  before_filter :check_login
  before_filter :redirect_to_customer_page
  before_filter :check_permissions
  
  layout 'admin_settings', :only => [:index, :edit]
  ssl_exceptions []
  
  def async_list
    render :json => CancellationReason.all
  end
  
  def async_update
    reason = CancellationReason.find(params[:id])
    reason.update_attributes(params[:reason])
    notify(Notification::UPDATED, reason)
    render :json => reason
  end
  
  def async_create
    reason = CancellationReason.create(params[:reason])
    notify(Notification::CREATED, reason)
    render :json => reason
  end

  def index
    add_breadcrumb "CancellationReasons"
    @cancellation_reasons = CancellationReason.all
  end

  def edit
    add_breadcrumb "CancellationReasons", "/admin/cancellation_reasons"
    add_breadcrumb "Edit"
    @cancellation_reason = CancellationReason.find(params[:id])
  end

  def update
    cancellation_reason = CancellationReason.find(params[:id])
    if cancellation_reason.update_attributes(params[:cancellation_reason])
      redirect_to :action => 'index'
    else
      render :action => 'edit'
    end
  end

  def create
    reason = CancellationReason.create(params[:cancellation_reason])
    notify(Notification::CREATED, reason)
    redirect_to :action => 'index'
  end

  def destroy
    cancellation_reason = CancellationReason.find(params[:id])
    if cancellation_reason
      cancellation_reason.destroy 
      notify(Notification::DELETED, cancellation_reason)
    end
    redirect_to "/admin/cancellation_reasons"
  end

end