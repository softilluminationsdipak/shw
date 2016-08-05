class Admin::RenewalStatusesController < ApplicationController
	before_filter :check_login
  before_filter :redirect_to_customer_page
  before_filter :check_permissions

	layout 'admin_settings'

  def index
    add_breadcrumb "Statutes"
  	@renewal_statuses = RenewalStatus.all
    @renewal_status = RenewalStatus.new
  end

  def edit
    add_breadcrumb "Statutes","/admin/renewal_statuses"
    add_breadcrumb "Edit"
    @renewal_status = RenewalStatus.find(params[:id])
  end

  def update
    @renewal_status = RenewalStatus.find(params[:id])
    if @renewal_status.update_attributes(params[:renewal_status])
      notify(Notification::UPDATED, @renewal_status)
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
    @renewal_status = RenewalStatus.new(params[:renewal_status])
    csid = RenewalStatus.last.present? ? RenewalStatus.last.csid.to_i + 1 : 0
    @renewal_status.csid = csid
    if @renewal_status.valid?
      @renewal_status.save 
      notify(Notification::CREATED, @renewal_status)
    end
    respond_to do |format|
      format.html
      format.js
    end    
  end

  def destroy
  	@renewal_status = RenewalStatus.find(params[:id])
  	if @renewal_status
      @renewal_status.destroy 
      notify(Notification::CREATED, @renewal_status)
    end
  	redirect_to "/admin/renewal_statuses"
  end
end
