class Admin::IpaddressesController < ApplicationController
  
  before_filter :check_login
  before_filter :check_permissions
  layout 'admin_settings'

  def index
  	@ip_addresses = Ipaddress.order('created_at DESC')
  	@ip_address = Ipaddress.new
  end

  def create
  	@ip_address = Ipaddress.new(params[:ipaddress])
  	if @ip_address.valid?
  		@ip_address.save 
  		notify(Notification::CREATED, @ip_address)
  	end
  	respond_to do |format|
  		format.js
  		format.html{}
  	end
  end

  def edit
  	@ip_address = Ipaddress.find(params[:id])
  end

  def update
  	@ip_address = Ipaddress.find(params[:id])
  	if @ip_address.update_attributes(params[:ipaddress])
      @msg = "success"
      notify(Notification::UPDATED, @ip_address)
    else
      @msg = "error"
    end
    respond_to do |format|
      format.html
      format.js
    end
  end

  def destroy
  	@ip_address = Ipaddress.find(params[:id])
  	@ip_address.destroy if @ip_address.present?
  	redirect_to admin_ipaddresses_path, notice: 'Successfully destroy'
  end

end
