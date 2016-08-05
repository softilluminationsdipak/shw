class Admin::GatewaysController < ApplicationController
	before_filter :redirect_to_customer_page
	before_filter :check_login
  before_filter :check_permissions
  
  layout 'admin_settings'

  def index
  	@gateways = Gateway.all
  	@gateway = Gateway.new  	
  end

  def edit
  	@gateway = Gateway.find(params[:id])
  end

  def create
  	@gateway = Gateway.new(params[:gateway])
  	if @gateway.valid?
  		@gateway.save
      notify(Notification::CREATED, @gateway)
  		redirect_to "/admin/gateways", :notice => "Successfully Done!"
  	else
  		redirect_to "/admin/gateways", :notice => @gateway.errors.full_messages.first
  	end  	  	
  end

  def update
  	@gateway = Gateway.find(params[:id])
  	if @gateway.update_attributes(params[:gateway])
      notify(Notification::UPDATED, @gateway)
  		redirect_to "/admin/gateways", :notice => "Successfully Updated"
  	else
  		redirect_to "/admin/gateways/edit/#{@gateway.id}", :notice => @gateway.errors.full_messages.first
  	end  
  end

  def destroy
  	@gateway = Gateway.find(params[:id])
    if @gateway.present?
  	  @gateway.destroy 
      notify(Notification::DELETED, @gateway)
    end
  	redirect_to "/admin/gateways", :notice => "Successfully destroy"
  end
  
end
