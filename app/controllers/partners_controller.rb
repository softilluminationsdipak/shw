class PartnersController < ApplicationController

	before_filter :authenticate_partner
	layout "bootstraplayout2"

	def index
		if params['start_date'].present? && params['end_date'].present? && params['start_date'].scan('/').size == 2 && params['end_date'].scan('/').size == 2
			@start_date 		= Date.strptime(params['start_date'], '%m/%d/%Y')
			@end_date 			= Date.strptime(params['end_date'], '%m/%d/%Y')
			@find_customer 	= current_partner.customers.where("DATE(created_at) >= ? and DATE(created_at) <= ?", @start_date.to_date, @end_date.to_date).order("created_at DESC")
			@customers 			= @find_customer.paginate(:page => params[:partners_page], :order => 'created_at DESC', :per_page => 50)
		else
			@find_customer  = current_partner.customers.order("created_at DESC")
			@customers 			= @find_customer.paginate(:page => params[:partners_page], :per_page => 50)
		end
		respond_to do |format|
    	format.html
    	format.csv { send_data @find_customer.to_csv2({}, @start_date, @end_date), :filename => "AffiliateLeads-#{current_partner.company_name.gsub(/[^0-9A-Za-z]/, '')}-#{Time.now.to_date.strftime('%m%d%Y')}" + ".csv" }
    	format.xls { send_data @find_customer.to_csv2({col_sep: "\t"}, @start_date, @end_date), filename: "AffiliateLeads-#{current_partner.company_name.gsub(/[^0-9A-Za-z]/, '')}-#{Time.now.to_date.strftime('%m%d%Y')}.xls"}
  	end
	end

	def generate_api_key
		token 						= current_partner.generate_unique_token
		@current_partner 	= current_partner
		current_partner.update_attributes(:auth_token => token)
		redirect_to my_account_path, :notice => "Successfully Updated! "
	end

	def auth_token
		@current_partner = current_partner
	end

	def token_destroy
		auth_token = AuthToken.find(params[:id])
		auth_token.destroy if auth_token.present?
		redirect_to partner_auth_token_path, :notice => "Successfully Deleted!"
	end

	def my_account
		@partner 	= current_partner
		@subId 		= ""
	end

	def update
		@partner = current_partner
		if @partner.update_attributes(params[:partner])
			redirect_to my_account_path, :notice => "Successfully Updated"
		else
			render :action => "my_account"
		end
	end

	def change_password
		@partner = current_partner
		if @partner.valid_password?(params[:partner][:old_password])
			if params[:partner][:password].to_s == params[:partner][:password_confirmation]
				@partner.update_attributes(params[:partner])
				flash[:success] = "Successfully Updated Password"
				redirect_to my_account_path
			else
				flash[:error] = "Password and Password Confirmation is not matched"
				redirect_to my_account_path
			end
		else
			flash[:error] = "Old Password is not valid!"
			redirect_to my_account_path
		end
	end

end
