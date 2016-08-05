class Admin::SalesController < ApplicationController
  
  before_filter :check_login
  before_filter :check_permissions
  
  def dashboard ## This action is used for sales person login - Dashboard page for Sale Person
    @page_title = "Sales"
    @selected_tab = 'index'
    render :action => 'dashboard', :layout => 'new_admin'
  end

  def null ## If No action found then redirect to sale Person
  	redirect_to "/admin/sales/dashboard"
  end
  
end