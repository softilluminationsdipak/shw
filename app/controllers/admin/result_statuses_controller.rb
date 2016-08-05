class Admin::ResultStatusesController < ApplicationController

	before_filter :check_login
  before_filter :redirect_to_customer_page
  before_filter :check_permissions

	layout 'admin_settings'

  def index
    add_breadcrumb "Statutes"
  	@result_statuses = ResultStatus.all
    @result_status = ResultStatus.new
  end

  def edit
    add_breadcrumb "Statutes","/admin/result_statuses"
    add_breadcrumb "Edit"
    @result_status = ResultStatus.find(params[:id])
  end

  def update
    @result_status = ResultStatus.find(params[:id])
    if @result_status.update_attributes(params[:result_status])
      notify(Notification::UPDATED, @result_status)
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
    @result_status = ResultStatus.new(params[:result_status])
    csid = ResultStatus.last.present? ? ResultStatus.last.csid.to_i + 1 : 0
    @result_status.csid = csid
    if @result_status.valid?
      @result_status.save 
      notify(Notification::CREATED, @result_status)
    end
    respond_to do |format|
      format.html
      format.js
    end    
  end

  def destroy
  	@result_status = ResultStatus.find(params[:id])
  	if @result_status
      @result_status.destroy 
      notify(Notification::DELETED, @result_status)
    end
  	redirect_to "/admin/result_statuses"
  end

end
