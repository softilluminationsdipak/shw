class Api::V1::CustomersController < Api::V1::BaseController

	def add_customer_for_get_a_quote
		@customer = Customer.new(params[:customer])
		@company = Partner.find_by_auth_token(params[:auth_token]) if params[:auth_token].present?
		if check_valid_params(params)
			if @company.present? && @company.is_access_approved?
				begin
					@customer.partner_id 		= @company.id
					@customer.datetimestamp = set_date_format_for_datetimestamp(params[:customer][:datetimestamp])
					@customer.properties.build(params[:property])  ## Create Property
					@customer.pay_amount 		= 499.95  ## For Billing Info 
					@customer.customer_from = "api"  ## For API customer Tracking 
					@customer.subid 				= params[:customer][:subID] if params[:customer][:subID].present?

					if params[:property][:state].present? && params[:property][:state].size >= 3
						render_json({:message => "The format for #{params[:property][:state]} field should be two-letters.", :status => 401}.to_json)							
					elsif not State.active_api.map(&:name).include?(params[:property][:state].upcase)				
						if @customer.valid? && @customer.save
							render_json({:message => "Sorry, we currently don't offer coverage in #{params[:property][:state].upcase} - please stay tuned!", :status => 200}.to_json)	
						else
							render_json({:errors => @customer.errors.full_messages, :status => 401}.to_json)
						end							
					else
  					if @customer.valid? && @customer.save
  						@customer.send_mail_about_new_price_quote(@customer)
  						render_json({:message => "Accepted", :status => 200}.to_json)
  					else
  						render_json({:errors => @customer.errors.full_messages, :status => 401}.to_json)
  					end
  				end

  			rescue ArgumentError => e
					render_json({:errors => e.to_s, :status => 401}.to_json)	    				
				rescue NoMethodError => e
					render_json({:errors => "You are not passing a proper data please check that.", :status => 401}.to_json)	    				
				end							
			else
    		render_json({:errors => "You don't have access!", :status => 401}.to_json)	
    	end
		else
			check_validations_for_add_customer_for_get_a_quote(params)
		end
	end

	def generate_lead
		if check_valid_lead_params(params)
			lead = Lead.new(params[:lead])
			if lead.valid?
				lead.save
				render_json({:message => "Accepted", :status => 200}.to_json)
			else
				render_json({:errors => lead.errors.full_messages.last, :status => 401}.to_json)
			end
		else
			check_validations_for_add_lead(params)
		end
	end

	private
	
	def set_date_format_for_datetimestamp(newdt)
		newdt1 = newdt.to_datetime.strftime("%m-%d-%Y %H:%M:%S")
		DateTime.strptime(newdt1, "%m-%d-%Y %H:%M:%S").strftime("%d-%m-%Y %H:%M:%S")
	end

	def check_validations_for_add_customer_for_get_a_quote(params)
		if !params[:customer].present?
			render_json({:errors => "Customer not found!", :status => 401}.to_json)
		elsif !params[:auth_token].present? 
			render_json({:errors => "Token not found!", :status => 401}.to_json)
		elsif !params[:customer][:leadid].present?
			render_json({:errors => "LeadID is not present!", :status => 401}.to_json)
		elsif !params[:property][:address].present?
			render_json({:errors => "Address is not present!", :status => 401}.to_json)	
		elsif !params[:property][:city].present?
			render_json({:errors => "City is not present!", :status => 401}.to_json)	
		elsif !params[:property][:state].present?
			render_json({:errors => "State is not present!", :status => 401}.to_json)	
		elsif !params[:property][:zip_code].present?
			render_json({:errors => "Zipcode is not present!", :status => 401}.to_json)	
		elsif !params[:customer][:datetimestamp].present?
			render_json({:errors => "Datetimestamp is not present!", :status => 401}.to_json)	
		end
	end

	def check_valid_params(params)
		params[:customer].present? && params[:auth_token].present? && params[:customer][:leadid].present? && params[:property][:address].present? && params[:property][:city].present? && params[:property][:state].present? && params[:property][:zip_code].present?
	end

	def check_valid_lead_params(params)
		params[:lead].present? && params[:lead][:first_name].present? && params[:lead][:last_name].present? && params[:lead][:work_phone].present? && params[:lead][:email].present? && params[:lead][:address].present? && params[:lead][:city].present? && params[:lead][:state].present? && params[:lead][:type_of_home].present?
	end

	def check_validations_for_add_lead(params)
		if !params[:lead].present?
			render_json({:errors => 'Lead not found', :status => 401}.to_json)
		elsif !params[:lead][:first_name].present?
			render_json({:errors => 'First Name is not present!', :status => 401}.to_json)
		elsif !params[:lead][:last_name].present?
			render_json({:errors => 'Last Name is not present!', :status => 401}.to_json)
		elsif !params[:lead][:work_phone].present?
			render_json({:errors => 'Work Phone is not present!', :status => 401}.to_json)
		elsif !params[:lead][:email].present?
			render_json({:errors => 'Email is not present!', :status => 401}.to_json)
		elsif !params[:lead][:address].present?
			render_json({:errors => 'Address is not present!', :status => 401}.to_json)
		elsif !params[:lead][:city].present?
			render_json({:errors => 'City is not present!', :status => 401}.to_json)
		elsif !params[:lead][:state].present?
			render_json({:errors => 'State is not present!', :status => 401}.to_json)
		elsif !params[:lead][:type_of_home].present?
			render_json({:errors => 'Type of home is not present!', :status => 401}.to_json)
		end											
	end

end
