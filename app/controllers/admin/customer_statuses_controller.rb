class Admin::CustomerStatusesController < ApplicationController
	before_filter :check_login
  before_filter :redirect_to_customer_page
  before_filter :check_permissions
  
	layout 'admin_settings'
  
  def index
    add_breadcrumb "Statutes"
  	@customer_statuses = CustomerStatus.all
    @customer_status = CustomerStatus.new
  end

  def edit
    add_breadcrumb "Statutes","/admin/customer_statuses"
    add_breadcrumb "Edit"
    @customer_status = CustomerStatus.find(params[:id])
  end

  def update
    @customer_status = CustomerStatus.find(params[:id])
    if @customer_status.update_attributes(params[:customer_status])
      notify(Notification::UPDATED, @customer_status)
      @msg = "success"
    else
      @msg = "error"
    end
    respond_to do |format|
      format.html
      format.js
    end

  end

  def new
    @customer_status = CustomerStatus.new
  end

  def create
    @customer_status = CustomerStatus.new(params[:customer_status])
    csid = CustomerStatus.last.csid.to_i + 1
    @customer_status.csid = csid 
    if @customer_status.valid?
      @customer_status.save 
      notify(Notification::CREATED, @customer_status)
    end
    respond_to do |format|
      format.html
      format.js
    end
  end

  def disable
    @customer_status = CustomerStatus.find(params[:id])
    if params[:type].to_s === "disable"
      @customer_status.active = false
    elsif params[:type].to_s === "enable"
      @customer_status.active = true
    end
    @customer_status.save
    notify(Notification::UPDATED, @customer_status)
    redirect_to admin_customer_statuses_path
  end


  def destroy
  	@customer_status = CustomerStatus.find(params[:id])
  	if @customer_status
      @customer_status.destroy
      notify(Notification::DELETED, @customer_status)
    end
    flash[:notice] = "Successfully deleted!"
  	redirect_to admin_customer_statuses_path
  end


end
