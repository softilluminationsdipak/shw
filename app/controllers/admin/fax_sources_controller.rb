class Admin::FaxSourcesController < ApplicationController
  before_filter :check_login
  before_filter :redirect_to_customer_page
  before_filter :check_permissions
  
  layout 'new_admin', :except => [:index, :edit]
  layout 'admin_settings', :only => [:index, :edit]

  ssl_exceptions []

  def async_list
    render :json => FaxSource.all
  end
  
  def async_update
    source = FaxSource.find(params[:id])
    source.update_attributes(params[:fax_source])
    notify(Notification::UPDATED, source)
    render :json => source
  end
  
  def retrieve
    source = FaxSource.send(params[:id])
    source.retrieve!
    render :json => {}
  end

  def index
    add_breadcrumb "FaxSources"
    @fax_sources = FaxSource.all
  end

  def edit
    add_breadcrumb "FaxSources", "/admin/fax_sources"
    add_breadcrumb "Edit"
    @fax_source = FaxSource.find(params[:id])
  end

  def update
    fax_source = FaxSource.find(params[:id])
    if fax_source.update_attributes(params[:fax_source])
      notify(Notification::UPDATED, fax_source)
      redirect_to :action => 'index'
    else
      render :action => 'edit'
    end
  end


end
