require 'csv'
class Admin::PartnersController < ApplicationController
	before_filter :check_login
	before_filter :redirect_to_customer_page
	before_filter :check_permissions
	
	layout 'admin_settings'
	def index
		@companies = Partner.paginate(:page => params[:companies], :per_page => 30)
		if params[:id].present?
			@params_id = params[:id]
			@partner = Partner.find(params[:id])
			if params['start_date'].present? && params['end_date'].present?
				@start_date = Date.strptime(params['start_date'], '%m/%d/%Y')
				@end_date = Date.strptime(params['end_date'], '%m/%d/%Y')
				@find_customer = @partner.customers.where("DATE(created_at) >= ? and DATE(created_at) <= ?", @start_date.to_date, @end_date.to_date).order("created_at DESC")
				@customers = @find_customer.paginate(:page => params[:customers], :order => 'created_at DESC', :per_page => 30)
			else
				@find_customer = @partner.customers.order("created_at DESC")
				@customers = @find_customer.paginate(:page => params[:customers], :per_page => 30)
			end
		end
		respond_to do |format|
    	format.html
    	format.csv { send_data @find_customer.to_csv({}, @start_date, @end_date), :filename => "AffiliateLeads-#{@partner.company_name.gsub(/[^0-9A-Za-z]/, '')}-#{Time.now.to_date.strftime('%m%d%Y')}" + ".csv" }
    	format.xls { send_data @find_customer.to_csv({col_sep: "\t"}, @start_date, @end_date), filename: "AffiliateLeads-#{@partner.company_name.gsub(/[^0-9A-Za-z]/, '')}-#{Time.now.to_date.strftime('%m%d%Y')}.xls"}
  	end
	end

	def edit
		@company = Partner.find(params[:id])
	end

	def update
		@company = Partner.find(params[:id])
		if @company.update_attributes(params[:partner])
			notify(Notification::UPDATED, @company)
			flash[:success] = "Successfully Updated"
			redirect_to "/admin/partners/edit/#{@company.id}"
		else
			render  :action => "edit"
		end
	end

	def change_password
		@partner = Partner.find(params[:id])
		if params[:partner][:password].to_s == params[:partner][:password_confirmation]
			@partner.update_attributes(params[:partner])
			notify(Notification::UPDATED, @partner)
			flash[:success] = "Successfully Updated Password"
			redirect_to "/admin/partners/edit/#{@partner.id}"
		else
			flash[:error] = "Password and Password Confirmation is not matched"
			redirect_to "/admin/partners/edit/#{@partner.id}"
		end
	end

	def destroy
		@company = Partner.find(params[:id])
		if @company.present?
			@company.destroy
			notify(Notification::DELETED, @company)
		end
		redirect_to "/admin/partners"
	end

end