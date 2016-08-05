class Admin::PropertiesController < ApplicationController
  before_filter :check_login
  #before_filter :only_admin_access, except: [:async_get_for_customer, :async_create, :async_update ]
  before_filter :check_permissions
  ssl_exceptions []
  
  def async_get_for_customer
    render :json => Customer.find(params[:id]).properties
  end
  
  def async_update
    property = Address.find(params[:id])
    if params[:property][:state].present? && params[:property][:state].length > 2
    else
      property.update_attributes(params[:property])
      notify(Notification::CHANGED, { :message => 'changed', :subject => property })
    end
    render :json => property
  end
  
  def async_create
    property = Address.new(params[:property])
    property.addressable_id = params[:property][:addressable_id]
    property.addressable_type = params[:property][:addressable_type]
    property.save
    notify(Notification::CREATED, { :message => "added to Customer #{property.addressable.notification_summary}", :subject => property })
    render :json => property
  end
end
