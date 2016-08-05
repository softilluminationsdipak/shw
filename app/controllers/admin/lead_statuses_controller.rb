class Admin::LeadStatusesController < ApplicationController
	before_filter :check_login  
  before_filter :redirect_to_customer_page
  before_filter :check_permissions

	layout 'admin_settings'

  def index
    add_breadcrumb "Statutes"
  	@lead_statuses = LeadStatus.all
    @lead_status = LeadStatus.new
  end

  def edit
    add_breadcrumb "Statutes","/admin/lead_statuses"
    add_breadcrumb "Edit"
    @lead_status = LeadStatus.find(params[:id])
  end

  def update
    @lead_status = LeadStatus.find(params[:id])
    if @lead_status.update_attributes(params[:lead_status])
      notify(Notification::UPDATED, @lead_status)
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
    @lead_status = LeadStatus.new(params[:lead_status])
    csid = LeadStatus.last.present? ? LeadStatus.last.csid.to_i + 1 : 0
    @lead_status.csid = csid
    if @lead_status.valid?
      @lead_status.save 
      notify(Notification::CREATED, @lead_status)
    end
    respond_to do |format|
      format.html
      format.js
    end    
  end

  def destroy
  	@lead_status = LeadStatus.find(params[:id])
  	if @lead_status
      @lead_status.destroy 
      notify(Notification::DELETED, @lead_status)
    end
  	redirect_to "/admin/lead_statuses"
  end
end
