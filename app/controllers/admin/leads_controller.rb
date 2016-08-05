class Admin::LeadsController < ApplicationController
	layout 'new_admin'
  before_filter :check_permissions

  def index
  	if current_account.admin?
  		@leads = Lead.order('created_at DESC').paginate(:page => params[:page], :per_page => 50)
  	else
  		redirect_to root_path
  	end
  end

  def show
  	@lead = Lead.find(params[:id])
  end

end
