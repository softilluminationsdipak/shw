class Admin::CustomersController < ApplicationController
  before_filter :check_login, :except => [:esign]
  before_filter :assemble_search_string, :only => [:async_advanced_search_check, :advanced_search]
  before_filter :check_permissions

  ssl_exceptions []

  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::SanitizeHelper
  #FIXME customer_can :update, :claims, :edit, :claim_history, :contract, :esign
  
  def index ## Used for Sales 
  end

  def update_credit_card_to_non_admin
    customer = Customer.find(params[:id])
    if customer.is_show_credit_card == true
      customer.is_show_credit_card = false
    else
      customer.is_show_credit_card = true
    end
    customer.save
    redirect_to :back
  end

  def async_get_overrides ## used for Sales
    customer = Customer.find(params[:id])
    render :json => customer.contract_overrides
  end
  
  def revert_to_new
    offset = (params[:page].to_i - 1) * params[:count].to_i
    ids = Customer.find(:all, :select => 'id', :order => 'updated_at DESC', :readonly => true,
                        :conditions => { :status_id => Customer.id_for_status(params[:id].to_s) },
                        :offset => offset, :limit => 30).collect(&:id)

    Customer.update_all("status_id = #{Customer.id_for_status(:new)}", "id IN (#{ids.join(',')})") unless ids.empty?
    
    render :json => { :ids => ids }
  end

  def revert_to_new_without_ci
    @status = params[:status]
    ids = params[:ids]
    if ids.present?
      ids.split(",").each do |c|
        @customer = Customer.find(c)
        @customer.status_id = 0
        @customer.save
      end
    end
  end

  def change_status
    @status = params[:status]
    if params[:ids].present?
      params[:ids].split(",").each do |c|
        customer = Customer.find(c)
        customer.status_id = params[:new_status]
        customer.save
      end
    end
  end

  def contract
    # after login, if user is customer, he should only be able to see his own contract info.
    # so need to check authorization first

    @account = Account.find(session[:account_id]) rescue nil
    if @account.nil?
       redirect_to '/login'
    end
    #puts "\n\nAccount: #{@account.inspect}"
    #puts "param_id: #{params[:id]}"
    if @account.customer? # check ID info
      destination_in_error = "/admin/customers/edit/#{@account.parent.id}"
      id_with_prefix = @account.parent._contract_number

      if  id_with_prefix != params[:id]
        return redirect_to(destination_in_error)
      end
    end

    #pid     = params[:id].to_s
    #new_pid = pid[ 4 .. -1]
    #tcsid   = new_pid.to_i
    #if tcsid.present? && tcsid >= 100000
    #  id_match            = params[:id].match(/(#{$installation.invoice_prefix2})?0*(\d+)/i)
    #else
      id_match            = params[:id].match(/(#{$installation.invoice_prefix})?0*(\d+)/i)
    #end
    @customer           = Customer.find(id_match[2])
    @contract_number    = @customer.dashed_contract_number.delete('#')
    @payment            = "$%.2f" % @customer.pay_amount.to_f
    @purchase_date      = @customer.cust_purchase_date #(!@customer.transactions.present? && @customer.transactions.approved.empty? ? @customer.date : @customer.transactions.approved.last.created_at.in_time_zone(EST)).strftime("%B %d, %Y") 
    @home_type          = @customer.formatted_home_type
    @home_size          = @customer.home_size
    @billing_address    = @customer.first_billing_address.to_s_for_contract
    @coverage_address   = @customer.first_property.to_s_for_contract
    state               = State.find_by_name(@customer.state)
    if state.present? and state.tos.present?
      @tos                = Content.tos_for2(@customer) #Content.tos_for_dupl(@customer, state.tos)
    else
      @tos                = Content.tos_for(@customer)
    end
    num_payments        = @customer.num_payments_override == 0 ? '' : (@customer.num_payments_override || @customer.num_payments)
    @payment_schedule   = "#{num_payments} #{@customer.payment_schedule_override}"
    
    @package_coverage_sets = (@customer.package.coverages.empty? ? ["None"] : @customer.package.coverages.collect(&:coverage_name).collect(&:upcase))#.each_slice(3).to_a
    # If coverages is empty, we have to make it [[]] or else Prawn will complain
    @optional_coverage_sets = (@customer.coverages.empty? ? ["None"] : @customer.coverages.collect(&:coverage_name).collect(&:upcase))#.each_slice(3).to_a
    purchaseable_coverages = Coverage.all_optional - @customer.coverages
    @purchaseable_optional_coverage_sets = (purchaseable_coverages.empty? ? ["None"] : purchaseable_coverages.collect(&:coverage_name).collect(&:upcase))#.each_slice(3).to_a
    respond_to do |format|
       format.pdf do
        render :pdf => "#{$installation.name.delete(' ')}_Intro_Packet_Agreement_#{@customer.dashed_contract_number.delete('#')}", :layout => false
      end
    end
  end
  
  def async_get_customers ## Access by Sales 
    count = Customer.send(params[:id]).count
    if current_account.sales?
      customers = Customer.where("status_id != 4").where("status_id != 2").send(params[:id]).paginate(
      :per_page => (params[:CIPaginatorItemsPerPage] || 1).to_i,
      :page => params[:CIPaginatorPage], :order => 'id DESC')
    else
    customers = Customer.where("status_id != 2").send(params[:id]).paginate(
      :per_page => (params[:CIPaginatorItemsPerPage] || 1).to_i,
      :page => params[:CIPaginatorPage], :order => 'id DESC')
    end
    render :json => {
      :CIPaginatorPage => params[:CIPaginatorPage],
      :CIPaginatorItemCount => count,
      :CIPaginatorCollection => customers
    }
  end
  
  def list ## Used In Admin / Sales
    if current_account.role == "customer"
      redirect_to "/admin/customers/claims"
    else
      add_breadcrumb "Customers"
      
      @page_title = "Customers"
      @selected_tab = 'customers'
      @status = params[:id]
      @page = session[:last_customers_async_list_page][params[:id]] || 1      
      @count = Customer.count(:conditions => {
        :status_id => Customer.id_for_status(params[:id].to_s)
      })
      render :layout => 'new_admin'
    end
  end
  
  def async_list ## Used in Sales
    params[:id] ||= 'new'    
    session[:last_customers_async_list_page][params[:id]] = params[:CIPaginatorPage]    
    conditions = { :status_id => Customer.id_for_status(params[:id].to_s) }    
    customers = Customer.paginate(:page => params[:CIPaginatorPage],
                                  :per_page  => (params[:CIPaginatorItemsPerPage] || 1).to_i,
                                  :conditions => conditions, :order => 'id DESC')    
    count = Customer.count(:conditions => conditions)
    render :json => {
      :CIPaginatorPage => params[:CIPaginatorPage],
      :CIPaginatorItemCount => count,
      :CIPaginatorCollection => customers
    }
  end
  
  def async_get_page_data
    customer = Customer.find(params[:id])
    # This needs to be done here because there is no other place to perform this action
    #if customer.properties.length >= 1 then customer.update_coverage_address_and_drop_first_property end
    #if customer.coverage_address? then customer.properties << customer.build_and_nullify_property end
    customer_hash = {
      :id                     => customer.id,
      :name                   => customer.name,
      :from                   => customer.from,
      :contract_number        => customer.contract_number,
      :agent_id               => customer.agent_id,
      :added                  => customer.date ? customer.date.in_time_zone(EST).strftime("%m/%d/%y %I:%M %p EST") : '',
      :last_updated           => customer.updated_at ? customer.updated_at.in_time_zone(EST).strftime("%m/%d/%y %I:%M %p EST") : '',
      :first_name             => customer.first_name,
      :last_name              => customer.last_name,
      :email                  => customer.email,
      :phone                  => customer.customer_phone,
      :status_id              => customer.status_id,
      :contract_status_id     => customer.contract_status_id,
      :lead_status_id         => customer.lead_status_id,
      :cancellation_reason_id => customer.cancellation_reason_id,
      
      :billing_address => customer.billing_address,
      
      :list_price => "$%5.2f" % customer.list_price,
      :home_type => customer.home_type || '',
      :home_size_code => customer.home_size_code,
      :work_phone => customer.work_phone,
      :mobile_phone => customer.mobile_phone,
      :coverage_type => customer.coverage_type,
      :esigned => customer.esigned? ? 'Signed' : 'Unsigned',
      
      :last_login               => customer.account ? customer.account.last_login : nil,
      :has_web_account          => !customer.account.nil?,
      :call_back_on             => customer.call_back_on.try(:strftime, '%d-%b-%Y'),
      :first_property_zip_code  => customer.properties.empty? ? nil : customer.properties.first.zip_code,
      :update_by                => customer.update_by,
      :policy_signed            => customer.policy_signed,
      :year                     => customer.year,
      :month_fee => customer.month_fee.present? ? customer.month_fee.to_i : 0,
      :purchase_date => customer.cust_purchase_date,
      :last_updated_info => customer.last_updated_info
    }
    Coverage.all_optional.each { |cvg| 
      customer_hash["coverage_#{cvg.id}"] = (customer.coverage_addon || '').split(', ').include?(cvg.id.to_s)
    }
    
    agents_hash = {}
    Agent.all.each { |a| agents_hash[a.name] = a.id }
    
    packages_hash = {}
    Package.all.each { |p| packages_hash[p.package_name] = p.id }
    
    reasons_hash = {}
    CancellationReason.all.each { |r| reasons_hash[r.reason] = r.id }

    contract_hash = {}    
    ContractStatus.all.each {|r| contract_hash[r.contract_status] = r.id }
    
    lead_hash = {}
    LeadStatus.all.each {|r| lead_hash[r.lead_status] = r.id }    

    render :json => {
      :customer => customer_hash,
      :agentOptions => agents_hash,
      :cancelReasonOptions => reasons_hash,
      :packageOptions => packages_hash,
      :contractStatusOptions => contract_hash,
      :leadStatusOptions => lead_hash
    }
  end
  
  def async_get_billing_address
    customer = Customer.find(params[:id])
    render :json => customer.billing_address || {}
  end
  
  def async_update_billing_address
    customer = Customer.find(params[:id])
    params[:billing][:address_type] = 'Billing'
    updated = (customer.billing_address || customer.build_billing_address).update_attributes(params[:billing])
    notify(Notification::CHANGED, { :message => 'updated', :subject => customer.billing_address })
    render :json => updated
  end
  
  def async_get_billing_info
    customer = Customer.find(params[:id])
    ccn_method = "credit_card_number"
    #ccn = current_account.cannot_see_credit_card_number ? customer.credit_card_number_last_4 : customer.credit_card_number

    ccn = ""
    
    #if (current_account.parent_type == "Agent") && (current_account.parent.admin ==1)
    if current_account.role.to_s == "admin"
      ccn = customer.credit_card_number
    else
      ccn = customer.credit_card_number_last_4
    end


    render :json => {
      :num_payments => customer.num_payments,
      :pay_amount => customer.pay_amount,
      :total_paid => "%.2f" % (customer.num_payments.to_i * customer.pay_amount.to_f),
      :discount => customer.discount.nil? ? 'None' : "#{customer.discount.code}, #{customer.discount.amount} off",
      :credit_card_number => ccn,
      :expirationDate => customer.expirationDate,
      :subscription_id => customer.subscription_id
    }
  end
  
  # Deprecated
  def grant_web_account
    customer = Customer.find(params[:id])
    password = customer.grant_web_account
    if password
      Postoffice.template('Welcome', customer.email, {:customer => customer, :password => password},current_account.email).deliver if $installation.auto_delivers_emails
    end
    redirect_to "/admin/customers/edit/#{params[:id]}"
  end
  
  def async_grant_web_account
    customer = Customer.find(params[:id])
    result = customer.grant_web_account
    if result.length == 8
      Postoffice.template('Welcome', customer.email, {:customer => customer, :password => result},current_account.email).deliver if $installation.auto_delivers_emails
      render :json => {
        :text => "#{customer.name} has been granted a web account. Their password is \"#{result}\", and they have been emailed the \"Welcome\" email."
      }
    else
      render :json => { :text => result }
    end
  end
  
  def async_advanced_search_check
    begin
    render :json => {:count => eval(@search << 'count')}
    rescue
    end
  end
  
  def advanced_search
    @page_title = "Advanced Search Results"
    begin
      @customers = eval(@search << 'to_a')
    rescue
    end
    if @customers.present? && @customers.length == 1
      redirect_to(:action => 'edit', :id => @customers.first.id) 
    else
      @customers ||= []
      render :action => 'search', :layout => 'new_admin'
    end
  end
  
  def smart_search
    @page_title = "Search Results"
    q = params[:query].to_s.strip
    q_is_string = q.to_i == 0
    go_to_claim = false
    @customers = []
  
    if params[:param] == "phone"
      work_phone_customer = Customer.where("work_phone LIKE (?)", "%#{q}%")
      customer_phone_customer = Customer.where("customer_phone LIKE (?)", "%#{q}%")
      @customers = work_phone_customer + customer_phone_customer
    elsif params[:param] == "id" and params[:query].size >= 5 and !q_is_string
      customer = Customer.find_by_id(q.to_i)
      if customer.present?
        @customers = customer.present? ? [customer] : []
      else
        customer = Customer.find_by_id(q.to_s[ 1 .. -1])
        @customers = customer.present? ? [customer] : []
      end
    else
      if params[:param] == 'id'
        if q.include?('@')
          @customers = Customer.with_email(q)
        elsif q_is_string and q.length == 2
          @customers = Customer.with_state(q)
        elsif q =~ /-\d+$/
          @customers = Customer.with_claim_number(q)
          go_to_claim = true
        elsif q =~ /^\d{10}/ or q =~ /^\d{4}/
          @customers = Customer.with_phone(q)
        elsif q =~ /^\d+\s+\w+/i
          @customers = Customer.with_street(q)
        elsif q =~ /SHW1\d{5}/
          @customers = Customer.where 'id =?', q.gsub(/SHW1/,'').to_i
        elsif q =~ /shw1\d{5}/
          @customers = Customer.where 'id =?', q.gsub(/shw1/,'').to_i
        else
          begin
            @customers = [Customer.find(q)]
          rescue ActiveRecord::RecordNotFound
            @customers = []
          end
        end
      else
        # Prevent injection attacks
        allowed_params = ['first_name', 'last_name', 'email', 'street', 'city', 'state', 'zip_code', 'phone']
        @customers = allowed_params.include?(params[:param]) ? Customer.send("with_#{params[:param]}", q) : []
      end
    end    
    #redirect_to(:action => 'edit', :id => @customers.first.id, :anchor => go_to_claim ? 'claims' : '') and return if @customers.length == 1
    begin
      redirect_to("/admin/customers/edit/#{@customers.first.id}") and return if @customers.length == 1
    rescue
      @customers = []
    end
    @customers ||= []
    
    render :action => 'search', :layout => 'new_admin'
  end
  
  def index
    redirect_to :action => 'list', :id => 'new'
  end
  
  def edit ## used for Edit Customer - Sales
    add_breadcrumb "Customers","/admin/customers/list/new"
    add_breadcrumb "Edit"
    
    @selected_tab = 'edit'

    if params[:id] and params[:id].to_i > 0
      @customer = Customer.find_by_id(params[:id])
      if @customer.present?
        if current_account.role.to_s == 'customer' && current_account.parent_id != @customer.id
          redirect_to '/admin/login'
        else
          @page_title = "Customers - #{@customer.contract_number} #{@customer.name}"
          @property = @customer.properties.first || @customer.properties.build
          # Nullify agent_id if the agent no longer exists
          @customer.update_attributes({ :agent_id => nil }) if @customer.agent_id and @customer.agent.nil?
          @coverage_options = Coverage.all_optional
          if params[:print]
            render :layout => 'print', :action => 'print'
          else
            render :layout => current_account.customer? ? 'admin' : 'new_admin'
          end
        end
      else
        redirect_to '/admin/login'
      end
    else
      redirect_to :action => 'list', :id => 'new'
    end
  end

  def async_update
    customer = Customer.find(params[:id])
    begin
      callback_on_date = Date.parse(params[:customer][:call_back_on])
      params[:customer][:call_back_on] = callback_on_date.strftime("%Y/%m/%d")
    rescue 
    end

    if params[:customer][:home_type] && params[:customer][:home_type] == ''
      params[:customer][:home_type] = nil
    end
    params[:customer][:cc_by] = "admin"

    updated_by = update_last_change_field(params[:customer][:first_name].present? ? params[:customer][:first_name] : customer.first_name )
    params[:customer][:update_by] = updated_by

    customer.cancellation_reason_id = params[:customer][:cancellation_reason_id] if params[:customer][:cancellation_reason_id].present?
    customer.agent_id               = params[:customer][:agent_id] if params[:customer][:agent_id].present?
    customer.status_id              = params[:customer][:status_id] if params[:customer][:status_id].present?
    customer.subscription_id        = params[:customer][:subscription_id] if params[:customer][:subscription_id].present?
    customer.contract_status_id     = params[:customer][:contract_status_id] if params[:customer][:contract_status_id].present?
    customer.policy_signed          = params[:customer][:policy_signed] if params[:customer][:policy_signed].present?
    customer.year                   = params[:customer][:year] if params[:customer][:year].present?
    if params[:customer][:purchase_date].present?   
      pdate = Date.strptime(params[:customer][:purchase_date],"%m/%d/%Y")       
      params[:customer][:purchase_date] = pdate.strftime('%m/%d/%Y')
    end
    if params[:customer][:month_fee].present?
      if customer.renewals.present? 
        renewal = customer.renewals.last
        if renewal.ends_at.present?
          renewal.ends_at = renewal.ends_at.to_date - customer.month_fee.to_i.months + params[:customer][:month_fee].to_i.months
        end
        renewal.save if customer.valid?
      end 
      customer.month_fee              = params[:customer][:month_fee].present? ? params[:customer][:month_fee] : '0'
    end
    customer.save
    updated = customer.update_attributes(params[:customer])
    
    notify(Notification::CHANGED, { :message  => 'updated', :subject => customer}) if updated
    
    if params[:customer][:email] and customer.account
      customer.account.update_attributes({:email => customer.email})
    end
    
    render :json => { :result => 'ok' }
  end
  
  def update
    @customer = Customer.find params[:id]
    @property = @customer.properties.first || @customer.properties.build
    
    if params[:customer]
    	if params[:customer][:coverage_type] 
		  	params[:coverages] ||= {}
		  	params[:customer][:coverage_addon] = (params[:coverages].collect { |k,v| k }).join(', ')
			end
			
			if params[:customer][:home_type] and params[:customer][:home_type] == ''
				params[:customer][:home_type] = nil
			end
      updated_by = update_last_change_field(params[:customer][:first_name].present? ? params[:customer][:first_name] : @customer.first_name )
      params[:customer][:update_by] = updated_by
      customer_updated = @customer.update_attributes(params[:customer])
      notify(Notification::UPDATED, { :message  => 'updated', :subject => @customer }) if customer_updated
    end        
    @property.update_attributes(params[:property])
    if params[:customer] and params[:customer][:email] and @customer.account
      @customer.account.update_attributes({:email => @customer.email})
    end
    
    if current_account.customer?
      redirect_to '/admin/customers/claims'
    else
      redirect_to "/admin/customers/edit/#{@customer.id}##{params[:anchor]}"
    end
  end
  
  def add ## Used in Sale / Admin
    if current_account.role == "customer"
      redirect_to "/admin/customers/claims"
    else
      add_breadcrumb "Customers","/admin/customers/list/new"
      add_breadcrumb "Add Customer"
          
      @selected_tab = 'customers'
      @customer = Customer.new
      @property = @customer.properties.build
      @billing = @customer.build_billing_address
      render :layout => 'new_admin'
    end
  end
  
  def create ## Used for Adding Customer - Used for Sales / Admin
  	params[:customer][:disabled] = 0
    params[:customer][:pay_amount] = 499.95  ## For Billing Info 
    params[:customer][:customer_from] = "sales"    
    @customer = Customer.new(params[:customer])
    @customer.properties.build(params[:property])
    if @customer.valid?
      if params[:property][:state].present? && State.active_gaq.map(&:name).include?(params[:property][:state].upcase) == true 
        @customer.save
        update_by = update_last_change_field(@customer.first_name)
        @customer.update_attributes(:update_by => update_by)
        params[:billing][:address_type] = 'Billing'
        @customer.create_billing_address(params[:billing])
      else
        @msg = "#{params[:property][:state]} is not valid state"
      end
    else
      @msg = @customer.errors.full_messages.first
    end
    notify(Notification::CREATED, { :message  => 'created', :subject => @customer }) if @msg == "success"
    #customer.send_mail_about_new_price_quote(customer)
    #redirect_to :action => 'edit', :id => customer.id
    respond_to do |format|
      format.html{redirect_to :back}
      format.js
    end
  end
  
  def claims
    @selected_tab = 'claims'
    @customer = Customer.find current_account.parent.id
    #premier_condition = @customer.coverage_type.to_i != 1 ? 'AND premier != 1' : ''
    #@coverages = @customer.coverages | Coverage.find(:all, :conditions => ["optional = 0"])
    #@coverages = @customer.coverages | Coverage.find(:all, :conditions => ["optional = 0 #{premier_condition}"])
    @coverages = @customer.coverages | Coverage.find(:all, :conditions => ["optional = 0"])
    render :layout => 'admin'
  end
  
  def claim_history
    @selected_tab = 'history'
    @customer = Customer.find current_account.parent.id
    render :layout => 'admin'
  end
  
  def async_related_customers
    customer = Customer.find(params[:id])
    related = []#customer.related_customers.reject { |c| c.id == customer.id }
    render :json => related.collect { |c|
      {
        :contract => c.contract_number
      }
    }
  end
  
  def esign
    @customer = Customer.find params[:id]
  end

  def perform_relationship_actions
    # Find the primary account
    primary_account = Customer.find(params[:customers].index('primary') || params[:id])
    # Take the primary account's current property and make it into a property if it doesn't have any properties
    if primary_account.properties.empty?
      primary_account.properties << primary_account.build_and_nullify_property
    end
    # Create properties on the primary account for each of the identified properties
    params[:customers].select { |k,v| v == 'property' }.each do |id, action|
      customer = Customer.find(id)
      primary_account.properties << customer.build_and_nullify_property
      if customer.can_be_purged? then customer.destroy end
    end
    # Delete the identified customers
    Customer.destroy(params[:customers].select { |k,v| v == 'purge' }.collect { |id, action| id })
    # Redirect back to the edit page
    redirect_to "/admin/customers/edit/#{primary_account.id}"
  end

  def update_last_change_field(customer)
    if @current_account.present? && @current_account.parent_type.to_s.downcase == "agent"
      return updated_by = @current_account.parent.name
    elsif @current_account.present? &&  @current_account.parent_type.to_s.downcase == "customer"
      return updated_by = @current_account.parent.first_name
    elsif @current_account.present? &&  @current_account.parent_type.to_s.downcase == "contractor"
      return updated_by = @current_account.parent.first_name
    else
      return updated_by = customer
    end
  end

  def nmi_payment
    @customer = Customer.find(params[:id])
    if @customer.present?
      render :layout => "new_admin"
    else
      redirect_to root_path
    end
  end

  def search_customer
    unless current_account.admin?
      redirect_to '/admin/index' 
    else
      query = {}
      query = query.merge('first_name' => "first_name LIKE '%#{params[:first_name]}%'") if params[:first_name].present?
      query = query.merge('last_name' => "last_name LIKE '%#{params[:last_name]}%'") if params[:last_name].present?
      query = query.merge('email' => "email = '#{params[:email]}'") if params[:email].present?
      if params[:start_date].present? && params[:end_date].present?
        end_date = Date.strptime("#{params[:end_date]}", "%m/%d/%Y").to_date
        start_date = Date.strptime("#{params[:start_date]}", "%m/%d/%Y").to_date
        query = query.merge('date' => "DATE(created_at) BETWEEN '#{start_date}' and '#{end_date}'")
      end
      if query.present?
        customers = Customer.where(query.values.join(' and ')).order('created_at DESC')
        @customers = customers.paginate(:page => params[:page], :per_page => 50)
      else
        customers = nil
        @customers = nil
      end
      respond_to do |format|
        format.html{render :layout => 'new_admin'}
        format.csv { send_data customers.to_csv5({}), file_name: 'customers.csv'}
        format.xls { send_data customers.to_csv5({col_sep: "\t"}), file_name: 'customers.xls'}
      end
    end
  end

  protected
  
  def assemble_search_string
    @search = "Customer."
    if params[:query].present?
      params[:query].sort.each do |i, query|
        next if query[:value] == ''
        @search << %Q{#{query[:op]}_#{query[:param]}("#{query[:value]}").}
      end
    end
  end
  
end
