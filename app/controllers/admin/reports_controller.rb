class Admin::ReportsController < ApplicationController
	before_filter :check_login
	#layout 'admin_settings', :only => [:index]
	before_filter :redirect_to_customer_page
	#before_filter :only_admin_access
	before_filter :check_permissions	
	
	layout 'admin_setting2'
	
	def income_sources
		if request.post?
			if params[:graph_period].present? && params[:graph_period].to_s == "Day"
				params[:day] = Time.now  unless params[:day].present?
				@mweek_start = params[:day].to_datetime
				@mweek_end = params[:day].to_date
			elsif params[:graph_period].present? && params[:graph_period].to_s == "Week" || params[:graph_period].to_s == "Month" 
				params[:mweek_start] = Time.now  unless params[:mweek_start].present?
				params[:mweek_end] = Time.now  unless params[:mweek_end].present?
				@mweek_start = params[:mweek_start].to_datetime
				@mweek_end = params[:mweek_end].to_date
			else
				@mweek_start = Time.now - 1.month
				@mweek_end = Time.now.to_date
			end				
		else
			@mweek_start = Time.now - 1.month
			@mweek_end = Time.now.to_date
		end
		@l_customers = Customer.gaq_api_customer
		@m_customers = Customer.manual_customer
		@g_customers = Customer.gaq_with_cc_customer
		render layout: 'report'
	end

	def lead_by_agent
		acc_role = params[:agent_type] 
		acc_role = "customer" unless acc_role.present? 

		@lead_customer = Customer.lead_by_customer.joins(:partner).joins(:agent).group("agents.name").count
		if request.post? && (params[:my_agent_list].present? || (params[:mg_week_start].present? && params[:mg_week_end].present?) )
			my_agent_list = params[:my_agent_list] if params[:my_agent_list].present?
			if params[:mg_week_start].present? && params[:mg_week_end].present?
				mg_week_end = params[:mg_week_end].to_date
				mg_week_start = params[:mg_week_start].to_date
			end
			if params[:my_agent_list].present? && params[:mg_week_start].present? && params[:mg_week_end].present? 
				@customer_agent = Customer.joins(:account).where("accounts.role = ?", acc_role).where(created_at: (mg_week_start)..(mg_week_end)).joins(:agent).where(['agents.name IN (?)', my_agent_list]).group("agents.name").count
				@agent_customer = Customer.joins(:account).where("accounts.role = ?", acc_role).where(created_at: (mg_week_start)..(mg_week_end)).joins(:agent).where(['agents.name IN (?)', my_agent_list]).group("status_id").group("agents.name").order("status_id")
			elsif params[:my_agent_list].present? 
				@customer_agent = Customer.joins(:agent).joins(:account).where("accounts.role = ?", acc_role).where(['agents.name IN (?)', my_agent_list]).group("agents.name").count
				@agent_customer = Customer.joins(:agent).joins(:account).where("accounts.role = ?", acc_role).where(['agents.name IN (?)', my_agent_list]).group("status_id").group("agents.name").order("status_id")
			elsif params[:mg_week_start].present? && params[:mg_week_end].present?
				@customer_agent = Customer.joins(:agent).joins(:account).where("accounts.role = ?", acc_role).where(created_at: (mg_week_start)..(mg_week_end)).group("agents.name").count
				@agent_customer = Customer.joins(:agent).joins(:account).where("accounts.role = ?", acc_role).where(created_at: (mg_week_start)..(mg_week_end)).group("status_id").group("agents.name").order("status_id")
			end
		else
			@customer_agent = Customer.joins(:agent).joins(:account).where("accounts.role = ?", acc_role).group("agents.name").count
			@agent_customer = Customer.joins(:agent).joins(:account).where("accounts.role = ?", acc_role).group("status_id").group("agents.name").order("status_id")
		end
	end

	def affiliate_and_leads
		params[:mweek_start] = (Time.now - 1.month).to_date.strftime("%d-%m-%Y")  unless params[:mweek_start].present?
		params[:mweek_end] = Time.now.to_date.strftime("%d-%m-%Y")  unless params[:mweek_end].present?
		@mweek_start = params[:mweek_start].to_datetime
		@mweek_end = params[:mweek_end].to_date
		## Report 4
		@customer_group_with_partner = Customer.includes(:partner).where("partners.company_api_access = ?", "Approved").group('partners.id').count
		@api_customer_r = Customer.joins(:partner).where("partners.company_api_access = ?", "Approved").group("partners.email").where(created_at: @mweek_start..@mweek_end)
		render layout: 'report'
	end

	def index
		@total_customer = Customer.count
		@total_customer_with_gaq_and_cc =  Customer.gaq_with_cc_customer.where("status_id = 4").count
		#Customer.gaq_with_cc_customer.count
		@gaq_api_customer = Customer.gaq_api_customer.count
		@manual_customer = Customer.manual_customer.count
		@total_customer_without_gaq_and_cc = (@total_customer - (@gaq_api_customer + @manual_customer + @total_customer_with_gaq_and_cc))
		#Customer.gaq_without_cc_customer.count
		
		## Report 1
		if request.post?
			if params[:graph_period].present? && params[:graph_period].to_s == "Day"
				params[:day] = Time.now  unless params[:day].present?
				@mweek_start = params[:day].to_datetime
				@mweek_end = params[:day].to_date
			elsif params[:graph_period].present? && params[:graph_period].to_s == "Week" || params[:graph_period].to_s == "Month" 
				params[:mweek_start] = Time.now  unless params[:mweek_start].present?
				params[:mweek_end] = Time.now  unless params[:mweek_end].present?
				@mweek_start = params[:mweek_start].to_datetime
				@mweek_end = params[:mweek_end].to_date
			else
				@mweek_start = Time.now - 1.month
				@mweek_end = Time.now.to_date
			end				
		else
			@mweek_start = Time.now - 1.month
			@mweek_end = Time.now.to_date
		end
		@l_customers = Customer.gaq_api_customer
		@m_customers = Customer.manual_customer
		@g_customers = Customer.gaq_with_cc_customer

		## Report 2
		@lead_customer = Customer.lead_by_customer.joins(:partner).joins(:agent).group("agents.name").count
		if request.post? && (params[:my_agent_list].present? || (params[:mg_week_start].present? && params[:mg_week_end].present?) )
			my_agent_list = params[:my_agent_list] if params[:my_agent_list].present?
			if params[:mg_week_start].present? && params[:mg_week_end].present?
				mg_week_end = params[:mg_week_end].to_date
				mg_week_start = params[:mg_week_start].to_date
			end
			if params[:my_agent_list].present? && params[:mg_week_start].present? && params[:mg_week_end].present? 
				@customer_agent = Customer.where(created_at: (mg_week_start)..(mg_week_end)).joins(:agent).where(['agents.name IN (?)', my_agent_list]).group("agents.name").count
				@agent_customer = Customer.where(created_at: (mg_week_start)..(mg_week_end)).joins(:agent).where(['agents.name IN (?)', my_agent_list]).group("status_id").group("agents.name").order("status_id")
			elsif params[:my_agent_list].present? 
				@customer_agent = Customer.joins(:agent).where(['agents.name IN (?)', my_agent_list]).group("agents.name").count
				@agent_customer = Customer.joins(:agent).where(['agents.name IN (?)', my_agent_list]).group("status_id").group("agents.name").order("status_id")
			elsif params[:mg_week_start].present? && params[:mg_week_end].present?
				@customer_agent = Customer.joins(:agent).where(created_at: (mg_week_start)..(mg_week_end)).group("agents.name").count
				@agent_customer = Customer.joins(:agent).where(created_at: (mg_week_start)..(mg_week_end)).group("status_id").group("agents.name").order("status_id")
			end
		else
			@customer_agent = Customer.joins(:agent).group("agents.name").count
			@agent_customer = Customer.joins(:agent).group("status_id").group("agents.name").order("status_id")
		end
		## Report 3
		@claims = Claim.where("status_code IS NOT NULL").group(:status_code).count

		## Report 4
		@api_customer_r = Customer.lead_by_customer.joins(:partner).group("partners.email").count

		respond_to do |format|
    	format.html#{render :layout => "admin_settings"}
  	end
	end

	def customer_report
		@states = State.all.map(&:name)
		if params[:property_state].present? && params[:status].present?
			@find_customers  = Customer.with_state(params[:property_state]).with_status_id(params[:status])
		else
			@find_customers = Customer.with_state("AL").with_status_id(0)
		end		
		if params[:full_property_info].present? || params["full_property_info"].present?
			if params['full_property_info'].to_s == "true" || params[:full_property_info].to_s == "true"
				full_property_info = true
			else
				full_property_info = false
			end
		else
			full_property_info = false
		end
		@customers 			= @find_customers.paginate(:page => params[:customers])
		respond_to do |format|
    	format.html{render layout: 'report'}
    	format.csv { send_data @find_customers.to_csv3({}, params[:property_state], params[:status],full_property_info), :filename => "customer-#{Time.now.to_date.strftime('%m%d%Y')}" + ".csv" }
    	format.xls { send_data @find_customers.to_csv3({col_sep: "\t"}, params[:property_state], params[:status],full_property_info), filename: "customer-#{Time.now.to_date.strftime('%m%d%Y')}.xls"}
  	end
	end

	def missing_renewal_dates
		@find_customers =  MissingRenewalDate.order("cdate DESC") #Customer.includes(:renewals).where("customers.status_id = 4 and renewals.customer_id IS NULL").order("customers.created_at DESC")
		@customers = @find_customers.paginate(:page => params[:customers])
		respond_to do |format|
    	format.html{render layout: 'report'}
    	format.csv { send_data @find_customers.to_csv4({}), :filename => "missing_renewal_dates-#{Time.now.to_date.strftime('%m%d%Y')}" + ".csv" }
    	format.xls { send_data @find_customers.to_csv4({col_sep: "\t"}), filename: "missing_renewal_dates-#{Time.now.to_date.strftime('%m%d%Y')}.xls"}
  	end
	end

	def performance_report
		render layout: 'report1'	
	end
	
end