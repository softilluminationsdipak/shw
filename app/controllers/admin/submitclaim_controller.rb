class Admin::SubmitclaimController < ApplicationController
  
  before_filter :check_login
  before_filter :check_permissions
  layout 'new_admin'

  def index ## Used for listing submitclaim
  	#if params[:search].present?
  	#	@submitclaims = Submitclaim.search(params[:search], params)
  	#else
	  	@submitclaims = Submitclaim.paginate(:page => params[:page], :per_page => 50)
	  #end
  end
end
