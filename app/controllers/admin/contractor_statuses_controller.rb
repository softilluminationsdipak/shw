class Admin::ContractorStatusesController < ApplicationController
	before_filter :check_login
  before_filter :redirect_to_customer_page
  before_filter :check_permissions
  
	layout 'admin_settings'

  def index
    add_breadcrumb "Statutes"
  	@contractor_statuses = ContractorStatus.all
    @contractor_status = ContractorStatus.new
  end

  def edit
    add_breadcrumb "Statutes","/admin/contractor_statuses"
    add_breadcrumb "Edit"
    @contractor_status = ContractorStatus.find(params[:id])
  end

  def update
    @contractor_status = ContractorStatus.find(params[:id])
    if @contractor_status.update_attributes(params[:contractor_status])
      notify(Notification::UPDATED, @contractor_status)
      @msg = "success"
    else
      @msg = "error"
    end
    respond_to do |format|
      format.html
      format.js
    end
  end

  def create
    @contractor_status = ContractorStatus.new(params[:contractor_status])
    csid = ContractorStatus.last.present? ? ContractorStatus.last.csid.to_i + 1 : 0
    @contractor_status.csid = csid
    if @contractor_status.save
      notify(Notification::CREATED, @contractor_status)
    end
    respond_to do |format|
      format.html
      format.js
    end    
  end

  def destroy
  	@contractor_status = ContractorStatus.find(params[:id])
    if @contractor_status
  	  @contractor_status.destroy 
      notify(Notification::DELETED, @contractor_status)
    end
  	redirect_to "/admin/contractor_statuses"
  end

  def disable
    @contractor_status = ContractorStatus.find(params[:id])
    if params[:type].to_s === "disable"
      @contractor_status.active = false
    elsif params[:type].to_s === "enable"
      @contractor_status.active = true
    end
    @contractor_status.save
    notify(Notification::UPDATED, @contractor_status)
    redirect_to admin_contractor_statuses_path
  end

end
