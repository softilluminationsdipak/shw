class Admin::SettingsController < ApplicationController
  before_filter :check_login
  layout 'admin_settings'
  before_filter :check_permissions

  ssl_exceptions []
  
  def index
    add_breadcrumb "Settings"
    @selected_tab = 'settings'
    @page_title = 'Application Settings'
  end

  def settings
    add_breadcrumb "Settings"
    @selected_tab = 'settings'
    @page_title = 'Settings'
    render :layout => 'admin_settings'
  end

end

