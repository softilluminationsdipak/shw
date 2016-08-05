namespace :select do

  desc 'Add ipaddresses'
  task :add_ipaddress => :environment do
    Ipaddress.create(:ip => '43.242.118.118')
    Ipaddress.create(:ip => '163.53.176.103')
    Ipaddress.create(:ip => '103.250.160.167')
    Ipaddress.create(:ip => '103.251.226.181')
  end

  desc 'test admin'
  task :test_admin => :environment do
    Ipaddress.create(:ip => '103.251.226.149')
    agent = Agent.where("name = ?", 'Administrator').try(:last)
    account = Account.new( :parent_type => 'Agent', :email => 'dipak@softilluminations.com', :password => 'password@18', :role => 'admin', :timezone => -5 )
    account.parent_id = agent.id
    account.save
  end

  task :create_default_admin => :environment do
	return if Agent.count != 0

	agent = Agent.create({
	  :name => 'Administrator', 
	  :email => 'admin',
	  :admin => true
	})
	account = Account.create({
	  :parent_id => agent.id,
	  :parent_type => 'Agent',
	  :email => $installation.admin_email,
	  :password => 'password',
	  :role => 'admin',
	  :timezone => -5
	})
	Notification.notify(Notification::CREATED, { :subject => agent })
  end

  ## ===============
  desc "Add States"
  task :add_states => :environment do
  #	State.delete_all
    state = [ "AL","AK","AZ","AR","CO","CT","CA","DE","DC","FL","GA","HI","ID","IL","IN","IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE","NV","NH","NJ","NM","NC","ND","OH","OK","OR","PA","RI","SC","SD","TN","UT","VT","VA","WV","WI","WY","TX"]
    state.each do |i|
    	State.create(:name => i, :api => true, :gaq => true, :affiliate => true)
    end
    puts "Successfully Done!"
  end

  ## Contractor Page
  desc "Add Default Active and for warning set Hold Status"
  task :add_active_and_hold_status_to_contractor => :environment do
  	begin
  		active_status = ContractorStatus.find_by_contractor_status("Active")
  		hold_status = ContractorStatus.find_by_contractor_status("Hold")
  	rescue
      puts "====== Please run add_contractor_status rake task  ============"
  	end
  	if active_status.present? && hold_status.present?
  		Contractor.update_all(:status => active_status.csid)
  		Contractor.where("flagged = ?", true).update_all(:status => hold_status.csid)
  	end
  end

  desc "Add Contractor status"
  task :add_contractor_status => :environment do
  	ContractorStatus.delete_all
  	ContractorStatus.create(:csid => 0, :contractor_code => "submitted", :contractor_status => "Submitted", :active => true, :navigation => true)
  	ContractorStatus.create(:csid => 1, :contractor_code => "Active", :contractor_status => "Active", :active => true, :navigation => true)
  	ContractorStatus.create(:csid => 2, :contractor_code => "Inactive", :contractor_status => "Inactive", :active => true, :navigation => true)
  	ContractorStatus.create(:csid => 3, :contractor_code => "Hold", :contractor_status => "Hold", :active => true, :navigation => true)
  	ContractorStatus.create(:csid => 4, :contractor_code => "DNU", :contractor_status => "DNU", :active => true, :navigation => true)
  end

  desc 'Add Permission'
  task :add_permissions => :environment do
    module_name = {"admin/customer_statuses" => ['index', 'edit', 'new', 'update', 'create', 'disable', 'destroy'], 'admin/agents' => ['index', 'edit', 'new', 'create', 'update', 'destroy'], 'admin/accounts' => ['async_reset_password', 'async_grant_web_account'], 'admin/admin' => ['index', 'admin_dashboard', 'claims_dashboard', 'retriction', 'dashboard', 'login', 'logout', 'authenticate', 'null'], 'admin/affiliates' => ['create', 'index', 'show', 'edit', 'update', 'destroy'], 'admin/cancellation_reasons' => ['async_list', 'async_update', 'async_create', 'index', 'edit', 'update', 'create', 'destroy'], 'admin/claim_statuses' => ['disable', 'index', 'edit', 'update', 'create', 'destroy'], 'admin/claims' => ['async_update_claim_or_repair', 'async_claims', 'create', 'async_get_for_customer', 'async_create', 'dashboard', 'update_last_change_field', 'current_active_statuses', 'select_and_unselect_statues', 'update', 'edit', 'add_claim_notes', 'generate_pdf_for_buy_out'], 'admin/content' => ['async_load', 'async_save', 'async_list', 'async_create', 'reload_content', 'index', 'async_get_package_prices', 'edit', 'update', 'restore', 'destroy'], 'admin/contract_statuses' => ['index', 'edit', 'update', 'create', 'destroy'], 'admin/contractor_statuses' => ['disable', 'index', 'edit', 'update', 'create', 'destroy'], 'admin/contractors' => ['index', 'find_by_location', 'async_find_in_radius', 'async_create', 'async_get_contractors', 'async_get_web_account', 'update_invoice_receipt', 'edit', 'create', 'async_update', 'update', 'destroy', 'update_status'], 'admin/conversions' => ['transactions_to_utc', 'set_default_roles', 'account_for_agent', 'notes_timestamp_to_created_at', 'claims_timestamp_to_created_at', 'customers'], 'admin/credit_cards' => ['update', 'bill', 'destroy', 'list_for_customer', 'add_for_customer'], 'admin/customers' => ['index', 'update_credit_card_to_non_admin', 'async_get_overrides', 'revert_to_new', 'revert_to_new_without_ci', 'change_status', 'contract', 'async_get_customers', 'list', 'async_list', 'async_get_page_data', 'async_get_billing_address', 'async_update_billing_address', 'async_get_billing_info', 'grant_web_account', 'async_grant_web_account', 'async_advanced_search_check', 'advanced_search', 'smart_search', 'index', 'edit', 'async_update', 'update', 'add', 'create', 'claims', 'claim_history', 'async_related_customers', 'esign', 'perform_relationship_actions', 'nmi_payment', 'search_customer'], 'admin/discounts' => ['index', 'edit', 'update', 'create', 'destroy', 'async_validate'], 'admin/email_templates' => ['index', 'edit', 'update', 'create', 'destroy', 'async_quickly_email', 'async_quickly_email_with_js'], 'admin/fax_sources' => ['async_list', 'async_update', 'retrieve', 'index', 'edit', 'update'], 'admin/faxes' => ['async_list', 'index', 'async_list_for_contractor', 'async_list_for_customer', 'thumbnail', 'preview', 'download', 'async_assignment_search', 'async_assign', 'async_unassign', 'destroy'], 'admin/gateways' => ['index', 'edit', 'create', 'update', 'destroy'], 'admin/ip_tracks' => ['index'], 'admin/lead_statuses' => ['index', 'edit', 'update', 'create', 'destroy'], 'admin/leads' => ['index', 'show'], 'admin/merchant_accounts' => ['index', 'create', 'edit', 'update', 'destroy'], 'admin/notes' => ['async_get_for_customer', 'async_create', 'async_update', 'create', 'add', 'add_note', 'view_note', 'rating', 'download_note_attachment', 'update', 'destroy', 'update_note_reference'], 'admin/notifications' => ['index'], 'admin/packages' => ['index', 'update', 'update_coverages', 'create_coverage'], 'admin/partners' => ['index', 'edit', 'update', 'change_password', 'destroy'], 'admin/permissions' => ['index', 'edit', 'update', 'create', 'destroy'], 'admin/properties' => ['async_get_for_customer', 'async_create', 'async_update'], 'admin/renewal_statuses' => ['index', 'edit', 'update', 'create', 'destroy'], 'admin/renewals' => ['async_get_for_customer', 'async_create_for_customer', 'async_remove_for_customer'], 'admin/repairs' => ['index', 'work_order_rtf', 'work_order', 'async_toggle_status', 'async_toggle_authorization', 'async_unassign_contractor_for_claim', 'complete'], 'admin/reports' => ['income_sources', 'lead_by_agent', 'affiliate_and_leads', 'index', 'customer_report', 'missing_renewal_dates', 'performance_report'], 'admin/result_statuses' => ['index', 'edit', 'update', 'create', 'destroy'], 'admin/sales' => ['dashboard', 'null'], 'admin/settings' => ['index', 'settings'], 'admin/states' => ['index', 'edit', 'update', 'create', 'destroy'], 'admin/submitclaim' => ['index'], 'admin/tag_statuses' => ['index', 'edit', 'update', 'create', 'destroy'], 'admin/transactions' => ['index', 'async_get_for_customer', 'authorize_silent_post'], 'admin/subscriptions' => ['async_get_for_customer'], 'admin/ipaddresses' => ['index', 'create', 'edit', 'update', 'destroy']}
    module_name.each do |controller_name, action_name|      
      action_name.each do |a|
        if ['admin/settings', 'admin/result_statuses', 'admin/reports', 'admin/renewal_statuses', 'admin/partners', 'admin/packages', 'admin/notifications', 'admin/lead_statuses', 'admin/ip_tracks', 'admin/gateways', 'admin/fax_sources', 'admin/customer_statuses', 'admin/contractor_statuses', 'admin/contract_statuses', 'admin/claim_statuses', 'admin/cancellation_reasons', 'admin/tag_statuses', 'admin/states'].include?(controller_name)
          old_permission = Permission.where('module_name = ? && action_name = ?', controller_name.to_s, a.to_s)
          unless old_permission.present?
            Permission.create(:module_name => controller_name, :action_name => a)
          end
        else
          if (controller_name == 'admin/transactions' && a == 'authorize_silent_post' ) || (controller_name == 'admin/content' && a == 'async_get_package_prices')
            old_permission = Permission.where('module_name = ? && action_name = ?', controller_name, a)
            unless old_permission.present?
              Permission.create(:module_name => controller_name, :action_name => a, :is_sales_access => true, :is_claim_access => true, :is_affilate_access => true)
            end
          elsif controller_name == 'admin/email_templates' && ['async_quickly_email', 'async_quickly_email_with_js'].include?(a) 
            old_permission = Permission.where('module_name = ? && action_name = ?', controller_name, a)
            unless old_permission.present?
              Permission.create(:module_name => controller_name, :action_name => a, :is_sales_access => true, :is_claim_access => true)
            end
          elsif (controller_name == 'admin/discounts' && a == 'async_validate') || (controller_name == 'admin/admin' && ['index', 'logout'].include?(a)) || (a == 'null') || (controller_name == 'admin/customers' && ['add', 'create', 'update'].include?(a))
            old_permission = Permission.where('module_name = ? && action_name = ?', controller_name, a)
            unless old_permission.present?            
              Permission.create(:module_name => controller_name, :action_name => a, :is_sales_access => true, :is_claim_access => true, :is_affilate_access => true)
            end
          elsif (controller_name == 'admin/credit_cards') || (controller_name == 'admin/agents' && a == 'edit') || (controller_name == 'admin/accounts') || (controller_name == 'admin/sales')
            old_permission = Permission.where('module_name = ? && action_name = ?', controller_name, a)
            unless old_permission.present?            
              Permission.create(:module_name => controller_name, :action_name => a, :is_sales_access => true)
            end
          elsif (controller_name == 'admin/admin' && ['login', 'authenticate'].include?(a))
            old_permission = Permission.where('module_name = ? && action_name = ?', controller_name, a)
            unless old_permission.present?            
              Permission.create(:module_name => controller_name, :action_name => a, :is_admin_access => false)
            end
          elsif (a == 'claims_dashboard' && controller_name == 'admin/admin') || (controller_name == 'admin/claims' && a == 'dashboard')
            old_permission = Permission.where('module_name = ? && action_name = ?', controller_name, a)
            unless old_permission.present?            
              Permission.create(:module_name => controller_name, :action_name => a, :is_admin_access => true, :is_claim_access => true)
            end
          elsif controller_name == 'admin/submitclaim' || (controller_name == 'admin/customers' && ['index', 'grant_web_account', 'async_update_billing_address', 'revert_to_new_without_ci', 'async_grant_web_account', 'list', 'index', 'advanced_search', 'async_advanced_search_check', 'smart_search', 'async_get_customers', 'edit', 'async_get_page_data', 'async_update', 'contract', 'async_get_billing_address', 'async_get_overrides', 'async_get_billing_info'].include?(a)) || (controller_name == 'admin/renewals' && ['async_get_for_customer', 'async_create_for_customer', 'async_remove_for_customer'].include?(a)) || (controller_name == 'admin/properties') || (controller_name == 'admin/transactions' && a == 'async_get_for_customer') || (controller_name == 'admin/subscriptions' && a == 'async_get_for_customer')
            old_permission = Permission.where('module_name = ? && action_name = ?', controller_name, a)
            unless old_permission.present?            
              Permission.create(:module_name => controller_name, :action_name => a, :is_sales_access => true, :is_admin_access => true)
            end
          elsif (controller_name == 'admin/notes' && ['async_get_for_customer', 'async_create', 'async_update', 'update', 'destroy'].include?(a)) || (controller_name == 'admin/claims' && ['create', 'async_get_for_customer', 'async_create', 'async_update_claim_or_repair', 'edit', 'add_claim_notes', 'generate_pdf_for_buy_out', 'update', 'update_last_change_field'].include?(a))
            old_permission = Permission.where('module_name = ? && action_name = ?', controller_name, a)
            unless old_permission.present?            
              Permission.create(:module_name => controller_name, :action_name => a, :is_sales_access => true, :is_admin_access => true)
            end
          elsif (controller_name == 'admin/faxes' && ['async_list_for_customer'].include?(a)) || (controller_name == 'admin/contractors' && ['async_find_in_radius', 'async_create', 'find_by_location'].include?(a))
            old_permission = Permission.where('module_name = ? && action_name = ?', controller_name, a)
            unless old_permission.present?            
              Permission.create(:module_name => controller_name, :action_name => a, :is_sales_access => true, :is_admin_access => true)
            end
          elsif (controller_name == 'admin/customers' && a == 'esign')
            old_permission = Permission.where('module_name = ? && action_name = ?', controller_name, a)
            unless old_permission.present?            
              Permission.create(:module_name => controller_name, :action_name => a, :is_admin_access => false)
            end
          elsif (controller_name == 'admin/claims' && ['current_active_statuses', 'select_and_unselect_statues', 'async_claims'].include?(a))
            old_permission = Permission.where('module_name = ? && action_name = ?', controller_name, a)
            unless old_permission.present?            
              Permission.create(:module_name => controller_name, :action_name => a, :is_claim_access => true)
            end
          else
            old_permission = Permission.where('module_name = ? && action_name = ?', controller_name, a)
            unless old_permission.present?
              Permission.create(:module_name => controller_name, :action_name => a)
            end
            ## Don't Change
          end
        end
      end
    end
    puts 'Successfully Completed'
  end

  desc 'missing_renewal_dates data'
  task :missing_renewal_dates => :environment do ## rake select:missing_renewal_dates
    MissingRenewalDate.delete_all
    find_customers =  Customer.includes(:renewals).where("customers.status_id = 4").order("customers.created_at DESC")
    find_customers.each do |customer|
      if customer.renewals.blank?
        state  = customer.customer_state.present? ? customer.customer_state.upcase : customer.last_property_state
        total  = customer.transactions.present? ? customer.transactions.sum(&:amount).round(2) : 0.0
        MissingRenewalDate.create(:customer_id => customer.id, fullname: customer.cust_fullname, customer_state: state, no_of_transaction: customer.transactions.count, total: total, cdate: customer.created_at.strftime("%m/%d/%Y") )
      end
    end
  end
end