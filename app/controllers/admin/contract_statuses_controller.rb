class Admin::ContractStatusesController < ApplicationController
	before_filter :check_login
  before_filter :redirect_to_customer_page
  before_filter :check_permissions

	layout 'admin_settings'

  def index
    add_breadcrumb "Statutes"
  	@contract_statuses = ContractStatus.all
    @contract_status = ContractStatus.new
  end

  def edit
    add_breadcrumb "Statutes","/admin/contract_statuses"
    add_breadcrumb "Edit"
    @contract_status = ContractStatus.find(params[:id])
  end

  def update
    @contract_status = ContractStatus.find(params[:id])
    if @contract_status.update_attributes(params[:contract_status])
      notify(Notification::UPDATED, @contract_status)
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
    @contract_status = ContractStatus.new(params[:contract_status])
    csid = ContractStatus.last.present? ? ContractStatus.last.csid.to_i + 1 : 0
    @contract_status.csid = csid
    if @contract_status.save
      @contract_status.save
      notify(Notification::CREATED, @contract_status)
    end
    respond_to do |format|
      format.html
      format.js
    end    
  end

  def destroy
  	@contract_status = ContractStatus.find(params[:id])
  	if @contract_status
      @contract_status.destroy 
      notify(Notification::DELETED, @contract_status)
    end
  	redirect_to "/admin/contract_statuses"
  end
end
