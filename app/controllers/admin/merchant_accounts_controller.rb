class Admin::MerchantAccountsController < ApplicationController
	before_filter :redirect_to_customer_page
	before_filter :check_login
  before_filter :check_permissions
  
  layout 'admin_settings'

  def index
  	@merchant_accounts = MerchantAccount.all
  	@merchant_account = MerchantAccount.new
  end

  def create
  	@merchant_account = MerchantAccount.new(params[:merchant_account])
  	if @merchant_account.valid?
  		@merchant_account.save
  		redirect_to "/admin/merchant_accounts", :notice => "Successfully Done!"
  	else
  		redirect_to "/admin/merchant_accounts", :notice => @merchant_account.errors.full_messages.first
  	end  	
  end

  def edit
  	@merchant_account = MerchantAccount.find(params[:id])
  end

  def update
  	@merchant_account = MerchantAccount.find(params[:id])
  	if @merchant_account.update_attributes(params[:merchant_account])
  		redirect_to "/admin/merchant_accounts", :notice => "Successfully Updated"
  	else
  		redirect_to "/admin/merchant_accounts/edit/#{@merchant_account.id}", :notice => @merchant_account.errors.full_messages.first
  	end  
  end

  def destroy
  	@merchant_account = MerchantAccount.find(params[:id])
  	@merchant_account.destroy if @merchant_account.present?
  	redirect_to "/admin/merchant_accounts", :notice => "Successfully destroy"
  end

end
