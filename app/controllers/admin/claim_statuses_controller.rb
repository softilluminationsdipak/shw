class Admin::ClaimStatusesController < ApplicationController

	before_filter :check_login
  before_filter :redirect_to_customer_page
  before_filter :check_permissions
  
	layout 'admin_settings'

  def index
    add_breadcrumb "Statutes"
  	@claim_statuses = ClaimStatus.all
    @claim_status   = ClaimStatus.new
  end

  def edit
    add_breadcrumb "Statutes","/admin/claim_statuses"
    add_breadcrumb "Edit"
    @claim_status = ClaimStatus.find(params[:id])
  end

  def update
    @claim_status = ClaimStatus.find(params[:id])
    if @claim_status.update_attributes(params[:claim_status])
      notify(Notification::UPDATED, @claim_status)
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
    @claim_status = ClaimStatus.new(params[:claim_status])
    csid = ClaimStatus.last.present? ? ClaimStatus.last.csid.to_i + 1 : 0
    @claim_status.csid = csid
    if @claim_status.valid?
      @claim_status.save 
      notify(Notification::CREATED, @claim_status)
    end
    respond_to do |format|
      format.html
      format.js
    end    
  end

  def destroy
  	@claim_status = ClaimStatus.find(params[:id])
    if @claim_status
  	  @claim_status.destroy 
      notify(Notification::DELETED, @claim_status)
    end
  	redirect_to admin_claim_statuses_path, :notice => "Successfully destroyed!"
  end

  def disable
    @claim_status = ClaimStatus.find(params[:id])
    if params[:type].to_s === "disable"
      @claim_status.active = false
    elsif params[:type].to_s === "enable"
      @claim_status.active = true
    end
    @claim_status.save
    notify(Notification::UPDATED, @claim_status)
    redirect_to admin_claim_statuses_path
  end

end
