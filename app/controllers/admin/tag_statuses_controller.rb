class Admin::TagStatusesController < ApplicationController
	before_filter :check_login
  before_filter :redirect_to_customer_page
  before_filter :check_permissions

	layout 'admin_settings'

  def index
    add_breadcrumb "Statutes"
  	@tag_statuses = TagStatus.all
    @tag_status = TagStatus.new
  end

  def edit
    add_breadcrumb "Statutes","/admin/tag_statuses"
    add_breadcrumb "Edit"
    @tag_status = TagStatus.find(params[:id])
  end

  def update
    @tag_status = TagStatus.find(params[:id])
    if @tag_status.update_attributes(params[:tag_status])
      notify(Notification::UPDATED, @tag_status)
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
    @tag_status = TagStatus.new(params[:tag_status])
    csid = TagStatus.last.present? ? TagStatus.last.csid.to_i + 1 : 0
    @tag_status.csid = csid
    if @tag_status.valid?
      @tag_status.save 
      notify(Notification::CREATED, @tag_status)
    end
    respond_to do |format|
      format.html
      format.js
    end    
  end

  def destroy
  	@tag_status = TagStatus.find(params[:id])
  	if @tag_status
      @tag_status.destroy 
      notify(Notification::DELETED, @tag_status)
    end
  	redirect_to "/admin/tag_statuses"
  end
end
