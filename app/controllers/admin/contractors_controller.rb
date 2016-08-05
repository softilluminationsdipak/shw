class Admin::ContractorsController < ApplicationController
  include Admin::ContractorsHelper
  before_filter :check_login
  before_filter :redirect_to_customer_page
  before_filter :check_permissions

  layout 'new_admin', :only => ['index', 'edit', 'find_by_location']
  
#FIXME  contractor_can :update_invoice_receipt

  ssl_exceptions []
  
  def index
    if current_account.role == "customer"
      redirect_to "/admin/customers/claims"
    elsif current_account.role == 'sales'
      redirect_to "/admin/sales/dashboard"
    else        
      add_breadcrumb "Contractors"

      if params[:page] == nil then
        params[:page] = "0"
      end
          
      param_contractor_id = params[:contractor_id]    
      begin
        if param_contractor_id.present? 
          if param_contractor_id.to_s.scan("33").present?
            param_contractor_id = param_contractor_id.to_s.gsub("33",'') 
          else
            param_contractor_id = params[:contractor_id]
          end
        else
          param_contractor_id = ''
        end
      rescue
      end
      
      param_state = params[:state]
      param_zipcode = params[:zipcode]
      param_status = params[:status]

      @page_title = 'Contractors'
      @selected_tab = 'contractors'
      @contractor = Contractor.new

      query = {}
      if param_status.present? 
        query = query.merge({"status" => "status = #{param_status} "})
      end
      if param_zipcode.present?
        query = query.merge({"zipcode" => "addresses.zip_code = '#{param_zipcode}' "})  
      end
      if param_contractor_id.present?
        begin
          query = query.merge({"id" => "contractors.id = #{param_contractor_id}"})
        rescue
        end        
      end
      if param_state.present?
        query = query.merge({"state" => "addresses.state = '#{param_state}'" })
      end
      @query = query
      if params[:page] != "0" then
        if query.present?
          if query.values.size == 1
            @contractors = Contractor.joins(:address).where(query.values.first).starting_with_letter(params[:page])  
          else
            @contractors = Contractor.joins(:address).where(query.values.join(" and ")).starting_with_letter(params[:page])  
          end
        else
          @contractors = Contractor.joins(:address).starting_with_letter(params[:page])
        end
      else
        begin
        if query.present?
          if query.values.size == 1
            @contractors = Contractor.joins(:address).where(query.values.first).starting_with_non_letter  
          else
            @contractors = Contractor.joins(:address).where(query.values.join(" and ")).starting_with_non_letter  
          end
        else
          @contractors = Contractor.joins(:address).starting_with_non_letter
        end
        rescue
          @contractors = nil
        end
      end
      @address = Address.new
      if param_contractor_id.present? && Contractor.find_by_id(param_contractor_id).present?
        redirect_to "/admin/contractors/edit/#{param_contractor_id}"
      end
    end
  end
  
  def find_by_location
    @radius = params[:radius].to_f || 15
    @location = params[:location]
    @search_by_geocode_success = false

    is_only_digit = @location.gsub(/\d/,'')
    if is_only_digit == '' then
      is_geocode = (@location.length == 5)
      is_phone_number = (@location.length == 10)
    else
      if @location.gsub(/[^@]/,'').length >0 then
        is_email = true
      else
        is_company_name = true
      end
    end

    if is_geocode == true then
      begin
        @addresses = Address.where(:addressable_type => "Contractor").within(
        @radius, :origin => params[:location]
        ).includes(:addressable)#.order('distance ASC')

        @page_title = 'Contractors found by location'
        @selected_table = 'contractors'

        unless @addresses.nil?
          return render 'find_by_location'
        end
      rescue
        # failed search by geocode
      end
    elsif is_phone_number then
      @contractors = Contractor.all.select {|contractor| (contractor.phone_number == format_did(@location)) || (contractor.fax_number == format_did(@location))}
      unless @contractors.nil?
        @location = format_did(@location)
        @find_description = "Phone/Fax number"
        return render 'find_by_text'
      end
    elsif is_email then
      @contractors = Contractor.where(:email => @location)
      unless @contractors.nil?
        @find_description = "Email"
        return render 'find_by_text'
      end
    elsif is_company_name then
      @contractors = Contractor.where("company like ?", "%#{@location}%") #:company => @location)
      unless @contractors.nil?
        @find_description = "Company"
        return render 'find_by_text'
      end
    end
    # failed or empty result , when search contractors by geocode
    @addresses = nil
    @location = params[:location]

    render 'find_by_location_error'
  end
  
  def async_find_in_radius
    # search contractor by searchkey field
    # get value from params
    is_phone_number = false
    is_email = false
    is_company_name = false
    demo = "hidden"
    if params[:searchkey] != nil then
      search_key_value = params[:searchkey]
      is_only_digit = search_key_value.gsub(/\d/,'')
      if is_only_digit == '' then
        is_geocode = (search_key_value.length == 5)
        is_phone_number = (search_key_value.length == 10)
      else
        if search_key_value.gsub(/[^@]/,'').length >0 then
          is_email = true
        else
          is_company_name = true
        end
      end
      if params[:searchkey].present?
        addresses = Address.where("addressable_type = \"Contractor\" AND addressable_id IS NOT NULL").joins("inner join contractors on contractors.id = addressable_id").where("contractors.company like ?", "%#{params[:searchkey]}%")
      else
        addresses = []
      end        
      contractors_list = addresses.collect { |a|
        next if a.addressable.nil?
        c = a.addressable.to_hash
        c[:address] = a.to_hash
        c
      }.compact
      contractors_list
      demo = "visible"
    end

    if params[:radius] != "" then
      # search contractor within radius, from origin
      radius = params[:radius].to_f || 15
      origin = params[:location] || [params[:lat].to_f, params[:lng].to_f]
      
      #addresses = Address.where("addressable_type = \"Contractor\" AND addressable_id IS NOT NULL")
       #                  .within(radius, :origin => origin, :order => 'distance ASC')
        #                 .includes(:addressable)
                         #.order('distance ASC')
      addresses =  Address.where("addressable_type = \"Contractor\" AND addressable_id IS NOT NULL").includes(:addressable).within(radius, :origin => origin).by_distance(origin: origin)                         

      contractors_list = addresses.collect { |a|
        next if a.addressable.nil?
        c = a.addressable.to_hash
        c[:address] = a.to_hash
        c
      }.compact

    else
    # search contractor by add-on search key field
      if is_phone_number then
        contractors_extra = Contractor.all.select {|contractor| (contractor.phone_number == format_did(search_key_value)) ||  (contractor.fax_number == format_did(search_key_value))}
      elsif is_email then
        contractors_extra = Contractor.where(:email => search_key_value)
      elsif is_company_name then
        contractors_extra = Contractor.where("company like ?", "%#{search_key_value}%") 
      end
    end
    unless demo.to_s == "visible"
      unless contractors_extra.nil?
        contractors_list = contractors_extra.collect { |c|
          next if c.nil?
          c.to_hash
        }.compact 
      end
    end

    render :json => contractors_list
  end
  
  def async_create
    contractor = Contractor.create(params[:contractor])
    params[:address][:address_type] = 'Contractor'
    contractor.create_address(params[:address])
    notify(Notification::CREATED, { :message => 'created', :subject => contractor })
    render :json => contractor.id
  end
  
  def async_get_contractors
    session[:last_contractors_page] = params[:CIPaginatorPage]
    
    contractors = []
    if params[:CIPaginatorPage] == '#'
      contractors = Contractor.starting_with_non_letter
    else
      contractors = Contractor.starting_with_letter(params[:CIPaginatorPage])
    end
    
    render :json => {
      :CIPaginatorPage => params[:CIPaginatorPage],
      :CIPaginatorCollection => contractors.collect { |c|
        {
          :id => c.id,
          :company => c.company,
          :contact => c.name,
          :title => c.job_title.capitalize,
          :email => c.email,
          :phone => c.phone_number,
          :stars => c.stars,
          :flagged => c.flagged,
          :min_claim => c.min_claim,
          :min_hour => c.min_hour
        }
      }
    }
  end
  
  def async_get_web_account
    render :json => Account.for_contractor_id(params[:id]).first || 'null'
  end
  
  def update_invoice_receipt
    Contractor.find(params[:id]).update_attributes(params[:contractor])
    redirect_to :controller => 'repairs', :action => 'index'
  end
  
  def edit
    if current_account.admin?
      add_breadcrumb "Contractors","/admin/contractors"
      add_breadcrumb "Edit"
      
      @selected_tab = 'contractors'
      @contractor = params[:id].to_i == 0 ? Contractor.first : Contractor.find(params[:id])
      @page_title = "Contractors - #{@contractor.company}"
      @faxes = Fax.for_contractor(@contractor.id) if @contractor.present? 
    elsif current_account.role == 'sales' 
      #redirect_to '/admin/sales/dashboard'
      @contractor = params[:id].to_i == 0 ? Contractor.first : Contractor.find(params[:id])
    else
      @contractor = params[:id].to_i == 0 ? Contractor.first : Contractor.find(params[:id])
      #redirect_to '/admin/claims/dashboard'
    end
  end
  
  def create
    @contractor = Contractor.new(params[:contractor])
    params[:address][:address_type] = 'Contractor'
    @address = @contractor.build_address(params[:address])
    if @contractor.save
      notify(Notification::CREATED, { :message => 'created', :subject => @contractor })
      redirect_to :action => 'edit', :id => @contractor.id
    else
      redirect_to :action => 'index'
    end
  end
  
  def async_update
    contractor = Contractor.find(params[:id])
    no_email_before = contractor.email.empty?
    address = contractor.address || contractor.build_address
    if contractor.update_attributes(params[:contractor]) && address.update_attributes(params[:address])
      contractor.account.update_attributes({ :email => contractor.email }) unless contractor.account.nil?
      notify(Notification::CHANGED, { :message => 'updated', :subject => contractor })
      if no_email_before and !contractor.email.empty?
        contractor.grant_account_and_send_welcome_email(current_account) if current_account.present? 
        notify(Notification::INFO, { :message => 'granted web access', :subject => contractor })
      end
    end
    render :json => contractor
  end
  
  def update
    begin
      @contractor = Contractor.find(params[:id])
      no_email_before = @contractor.email.empty?
      @address = @contractor.address || @contractor.build_address
      params[:address][:address_type] = 'Contractor'
      params[:contractor][:last_update_by] = update_last_change_field("")

      if @contractor.update_attributes(params[:contractor]) && @address.update_attributes(params[:address])
        unless @contractor.account.nil? then @contractor.account.update_attributes({ :email => @contractor.email }) end
        notify(Notification::CHANGED, { :message => 'updated', :subject => @contractor })
        if no_email_before and !@contractor.email.empty?
          @contractor.grant_account_and_send_welcome_email(current_account)
          notify(Notification::INFO, { :message => 'granted web access', :subject => @contractor })
        end
        redirect_to :action => 'edit', :id => params[:id]
      else
        render :action => 'edit', :id => params[:id]
      end
    rescue => e 
      redirect_to :action => 'edit', :id => params[:id]
    end
  end
  
  def destroy
    contractor = Contractor.find params[:id]
    contractor.destroy
    redirect_to :action => 'index'
  end

  def update_last_change_field(contractor)
    @current_account = current_account
    if @current_account.present? && @current_account.parent_type.to_s.downcase == "agent"
      return updated_by = @current_account.parent.name
    elsif @current_account.present? &&  @current_account.parent_type.to_s.downcase == "customer"
      return updated_by = @current_account.parent.first_name
    elsif @current_account.present? &&  @current_account.parent_type.to_s.downcase == "contractor"
      return updated_by = @current_account.parent.first_name
    else
      return updated_by = contractor
    end
  end

  def update_status
    @contractor = Contractor.find(params[:id])
    @status = ContractorStatus.active_status.find_by_csid(params[:status])
    if params[:status].present?
      @contractor.update_attributes(:status => params[:status])
    end
    respond_to do |format|
      format.js
    end
  end

  private

  def only_admin
    redirect_to '/admin/sales/dashboard'
  end
end
