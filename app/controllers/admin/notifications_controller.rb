class Admin::NotificationsController < ApplicationController
  before_filter :check_login
  before_filter :redirect_to_customer_page
  #before_filter :only_admin_access
  before_filter :check_permissions

  layout 'new_admin'

  ssl_exceptions []
  
  def index
    add_breadcrumb "Notifications"
    
    @page_title = 'Notifications'
    @selected_tab = 'dashboard'
    @notifications = Notification.order('created_at DESC').paginate(:page => params[:page], :per_page  => 25)
  end
end
