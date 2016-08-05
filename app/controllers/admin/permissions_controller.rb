class Admin::PermissionsController < ApplicationController
  layout 'admin_settings'
  before_filter :check_permissions

  def index
  	@permissions = Permission.order('created_at DESC')
  	@permission = Permission.new
  end

  def create
  	@permission = Permission.new(params[:permission])
  	if @permission.save
      notify(Notification::CREATED, @permission)
  		redirect_to admin_permissions_path, notice: 'Successfully Created.'
  	else
  		redirect_to admin_new_permission_path, notice: @permission.errors.full_messages.try(:first)
  	end
  end

  def update
  	@permission = Permission.find(params[:id])
  	if @permission.update_attributes(params[:permission])
      notify(Notification::UPDATED, @permission)
  		redirect_to admin_permissions_path, notice: 'Successfully Updated.'
  	else
  		redirect_to admin_new_permission_path, notice: @permission.errors.full_messages.try(:first)
  	end	
  end

  def edit
  	@permission = Permission.find(params[:id])
  end

  def destroy
  	@permission = Permission.find(params[:id])
    if @permission.present?
  	  @permission.destroy 
      notify(Notification::DELETED, @permission)
    end
  	redirect_to admin_permissions_path, notice: 'Successfully Destroy'
  end

  private

  def find_permission
  	@permission = Permission.find(params[:id])
  end
end
