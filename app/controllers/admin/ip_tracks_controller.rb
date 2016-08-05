class Admin::IpTracksController < ApplicationController
  before_filter :check_login
  before_filter :redirect_to_customer_page
  before_filter :check_permissions

  protect_from_forgery
  layout 'new_admin'

  def index
    add_breadcrumb "IP Tracks"
    @ip_tracks = IpTrack.order('created_at DESC').paginate(:page => params[:ip_tracks], :per_page => 50)
  end
  
end
