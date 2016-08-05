class Admin::ClaimsController < ApplicationController
  before_filter :check_login
  before_filter :check_permissions
  
  ssl_exceptions []

  def async_update_claim_or_repair
    claim = Claim.find(params[:id])
    
    if params[:repair]
      begin
        unless params[:repair][:service_charge].nil?
          params[:repair][:service_charge].gsub!(/[^\d\.]/, '')
        end
        # Pre-authorize under or equal to $100
        unless params[:repair][:amount].nil?
          params[:repair][:amount].gsub!(/[^\d\.]/, '')
        end
      rescue
        # gsub for NilClass exception
      end

      if params[:repair][:amount].present? && params[:repair][:amount].to_f <= 100.0 
        params[:repair][:authorization] = 1 
      end
      # Never authorize $0 or allow null amounts
      if params[:repair][:amount].present? && params[:repair][:amount].to_f <= 0.0
        params[:repair][:amount]        = 0.0
        params[:repair][:authorization] = 0
      end
    
      should_email = false
      if claim.repair
        should_email  = params[:repair][:contractor_id] && (params[:repair][:contractor_id].to_i != claim.repair.contractor_id) && !claim.customer.email.blank?
        updated       = claim.repair.update_attributes(params[:repair])
        claim.update_attributes(:updated_by => update_last_change_field)
        notify(Notification::UPDATED, claim.repair) if updated      
      else # create
        repair = claim.create_repair(params[:repair])
        claim.update_attributes(:updated_by => update_last_change_field)
        notify(Notification::CREATED, { :message => 'assigned', :subject => repair })
        should_email = params[:repair][:contractor_id] && claim.repair.contractor && !claim.customer.email.blank?
      end
      if should_email

        puts "To customer: #{claim.customer.inspect}"

        Postoffice.template('Contractor Assigned', claim.customer.email, {:repair => claim.repair,
          :customer => claim.customer, :contractor => claim.repair.contractor, :service_charge => claim.repair.formatted_service_charge
        },current_account.email).deliver # if $installation.auto_delivers_emails

        puts "To contractor: #{claim.repair.contractor.inspect}"

        if claim.repair.present? && claim.repair.contractor.present? && claim.repair.contractor.email.present? 
          Postoffice.template('Customer Assigned', claim.repair.contractor.email , {:repair => claim.repair,
            :customer => claim.customer, :contractor => claim.repair.contractor, :service_charge => claim.repair.formatted_service_charge
          }).deliver # if $installation.auto_delivers_emails
        end
        claim.update_attributes(:updated_by => update_last_change_field)
        notify(Notification::INFO, { :message => "emailed contractor assignment notice", :subject => claim.customer })
      end
    elsif params[:status_code]
      old_status = claim.status
      claim.update_attributes({ :status_code => params[:status_code] })
      claim.update_attributes(:updated_by => update_last_change_field)
      notify(Notification::UPDATED, { :message => "changed from #{old_status} to #{claim.status}", :subject => claim })
    elsif params[:invoice_status]
      claim.update_attributes({ :invoice_status => params[:invoice_status] })
      claim.update_attributes(:updated_by => update_last_change_field)      
      ##notify(Notification::UPDATED, { :message => "changed from #{old_status} to #{claim.status}", :subject => claim })
    elsif params[:invoice_receive]
      claim.update_attributes({ :invoice_receive => params[:invoice_receive] })
      claim.update_attributes(:updated_by => update_last_change_field)            
    end
    render :json => claim
  end
  
  def async_claims
    session[:last_claims_page]  = params[:CIPaginatorPage] || 1
    session[:last_active_statuses]     = params[:CIFilterActiveFilters].split(',').collect(&:to_i)
    # Remove non-numbers and non-commas to prevent injection attacks
    allowed_statuses = params[:CIFilterActiveFilters].to_s.gsub(/[^\d,]/, '')
    conditions = "status_code IN (#{allowed_statuses})"
    #count = Claim.count(:conditions => conditions)
    count = Claim.where("status_code IN (?)", allowed_statuses).count
    claims = Claim.paginate(:page => params[:CIPaginatorPage],
                            :per_page  => (params[:CIPaginatorItemsPerPage] || 15).to_i,
                            :conditions => conditions, :order => "updated_at DESC")
              
    render :json => {
      :CIPaginatorPage => params[:CIPaginatorPage],
      :CIPaginatorItemCount => count,
      :CIPaginatorCollection => claims
    }
  end
  
  def create
    if params[:coverages] or params[:force_coverages]
      params[:coverages] ||= {}
      params[:claim][:standard_coverage] = (params[:coverages].collect { |k,v| k }).join(', ')
    end
    claim = Claim.new(params[:claim])
    claim.claim_text = "Claimed Items:\n#{claim.summary}\n\nClaim:\n#{claim.text}"
    claim.status_code = 2 # Placed by Customer
    claim.updated_by = update_last_change_field
    claim.save
    
    notify(Notification::CREATED, { :message => 'created', :subject => claim})
    
    if current_account.customer?
      redirect_to '/admin/customers/claims'
      Postoffice.template('New Claim by Customer',
        [$installation.admin_email, $installation.claims_email], {
        :customer => current_account.parent,
        :summary => claim.summary,
        :text => claim.text
      },current_account.email).deliver # if $installation.auto_delivers_emails
    else
      redirect_to "/admin/customers/edit/#{params[:claim][:customer_id]}#claims"
    end
  end
  
  def async_get_for_customer
    customer = Customer.find(params[:id])
    properties = {}
    customer.properties.find_valid_properties.each { |p| properties[p.to_s] = p.id }
    render :json => {
        :properties_options => properties,
        :claims => customer.claims
    }
  end
  
  def async_create
    params[:claim][:agent_name] = @current_account.parent.name
    params[:claim][:status_code] = 1 # Placed by Agent
    params[:claim][:updated_by] = update_last_change_field
    param_claim = params[:claim]
    claim = Claim.new(param_claim)
    claim.claim_text = param_claim["claim_text"]
    claim.address_id = param_claim["address_id"]
    claim.customer_id = param_claim["customer_id"]
    claim.save
    notify(Notification::CREATED, { :message => 'created', :subject => claim })
    render :json => {
      :date => claim.date.in_time_zone(EST).strftime("%m/%d/%y %I:%M %p"),
      :text => claim.text
    }
  end

  def dashboard
    if current_account.role == "customer"
      redirect_to "/admin/customers/claims"
    else    
      search_claim_id         =  params[:claim_id] || ''
      search_contract_id      =  params[:contract_id].to_s
      search_state            =  params[:state]
      search_new_claim_status =  params[:new_claim_status]
      search_invoice_status   =  params[:invoice_status]

      search_query = {}
      if search_claim_id.present?
        search_claim_id = search_claim_id.gsub(/[^0-9]/, '')
        search_query = search_query.merge({"id" => "claims.id = #{search_claim_id}"})
      end
      if search_contract_id.present?
        search_contract_id = search_contract_id.gsub(/[^0-9]/, '')
        search_query = search_query.merge({"contractor_id" => "claims.customer_id = '#{search_contract_id}'"})
      end
      if search_state.present?
        search_query = search_query.merge({"customer_state" => "customers.customer_state = '#{search_state}'"})
      end
      if search_new_claim_status.present?
        search_query = search_query.merge({"status" => "claims.status_code = #{search_new_claim_status}"})
      end
      if search_invoice_status.present?
        search_query = search_query.merge({"invoice_status" => "claims.invoice_status = '#{search_invoice_status}'"})
      end
      param_claim_status = params[:claim_status]
      session[:current_active_statuses] = Claim.statuses.collect { |k,v| v } unless session[:current_active_statuses]
      @active_statuses = session[:current_active_statuses]

      logger.warn("======sq====#{search_query.values}========")

      if params[:claim_status].present? && param_claim_status.to_i == 0
        redirect_to "/admin/cliams/dashboard" 
      else      
        if search_query.values.present?
          if search_query.values.size == 1
            @claims = Claim.joins(:customer).with_status_code.where("claims.status_code IN (?)",@active_statuses).where(search_query.values.first).order("updated_at DESC").paginate(:page => param_claim_status, :per_page => 15)
          else
            @claims = Claim.joins(:customer).with_status_code.where("claims.status_code IN (?)",@active_statuses).where(search_query.values.join(" and ")).paginate(:page => param_claim_status, :per_page => 15)
          end
        else 
          begin       
            @claims = Claim.with_status_code.where("status_code IN (?)",@active_statuses).order("updated_at DESC").paginate(:page => param_claim_status, :per_page => 15)        
          rescue
            @claims = nil
          end
        end
        render :layout => 'admin_setting2'
      end
    end
  end

  def update_last_change_field
    if @current_account.present? && @current_account.parent_type.to_s.downcase == "agent"
      return updated_by = @current_account.parent.name
    elsif @current_account.present? &&  @current_account.parent_type.to_s.downcase == "customer"
      return updated_by = @current_account.parent.first_name
    elsif @current_account.present? &&  @current_account.parent_type.to_s.downcase == "contractor"
      return updated_by = @current_account.parent.first_name
    end
  end

  def current_active_statuses
    @temp=ClaimStatus.where(active: true)
    status_id = params[:status_id]
     
    session[:current_active_statuses] = [] unless session[:current_active_statuses].present?
    if session[:current_active_statuses].present? && session[:current_active_statuses].include?(status_id.to_i)
      session[:current_active_statuses].delete(status_id.to_i)
    else
      session[:current_active_statuses] << status_id.to_i
    end    
    session[:current_active_statuses] = session[:current_active_statuses].uniq
    @active_statuses = session[:current_active_statuses] || Claim.statuses.collect { |k,v| v }
    @claims = Claim.with_status_code.where("status_code IN (?)",@active_statuses).order("updated_at DESC").paginate(:page => params[:claim_status], :per_page => 15)
    respond_to do |format|
      format.html{redirect_to "/admin/claims/dashboard?claim_status=params[:claim_status]"}
      format.js
    end
  end

  def select_and_unselect_statues
    type = params[:type]
    if type.to_s == "select_all"
      session[:current_active_statuses] = Claim.statuses.collect { |k,v| v }
    elsif type.to_s == "unselect_all"
      session[:current_active_statuses] = nil
      session[:current_active_statuses] = []
    else
      session[:current_active_statuses]
    end
    redirect_to "/admin/claims/dashboard"
  end

  def update
    @claim = Claim.find(params[:id])
    if params[:invoice_receive].present?
      begin
        claim_date =  Date.strptime(params[:invoice_receive], '%m/%d/%Y')
      rescue
        claim_date =  Date.strptime(params[:invoice_receive], '%d/%m/%Y')
      end
      @claim.update_attributes(:invoice_receive => claim_date,:invoice_status => 'Received')
    elsif !params[:claim].present? && params[:invoice_receive] == ""
      @claim.update_attributes(:invoice_receive => "")
    elsif params[:invoice_status].present?
      @claim.update_attributes(:invoice_status => params[:invoice_status])
    elsif !params[:claim].present? && params[:invoice_status].to_s == ""
      @claim.update_attributes(:invoice_status => nil)
    else
      if params[:claim].present?
        if params[:claim][:release_received].present?
          begin
            params[:claim][:release_received] = Date.strptime(params[:claim][:release_received], '%m/%d/%Y')
          rescue
            params[:claim][:release_received] = Date.strptime(params[:claim][:release_received], '%d/%m/%Y')
          end
        end
        if params[:claim][:release_sent].present?
          begin
            params[:claim][:release_sent] = Date.strptime(params[:claim][:release_sent], '%m/%d/%Y')
          rescue
            params[:claim][:release_sent] = Date.strptime(params[:claim][:release_sent], '%d/%m/%Y')
          end            
        end
        if params[:claim][:release_paid].present?
          begin
            params[:claim][:release_paid] = Date.strptime(params[:claim][:release_paid], '%m/%d/%Y')
          rescue
            params[:claim][:release_paid] = Date.strptime(params[:claim][:release_paid], '%d/%m/%Y')
          end
        end
        if params[:claim][:ctr_check_date].present?
          begin
            params[:claim][:ctr_check_date] = Date.strptime(params[:claim][:ctr_check_date], '%m/%d/%Y')
          rescue
            params[:claim][:ctr_check_date] = Date.strptime(params[:claim][:ctr_check_date], '%d/%m/%Y')
          end
        end
        if params[:claim][:rel_check_date].present?
          begin
            params[:claim][:rel_check_date] = Date.strptime(params[:claim][:rel_check_date], '%m/%d/%Y')
          rescue
            params[:claim][:rel_check_date] = Date.strptime(params[:claim][:rel_check_date], '%d/%m/%Y')
          end
        end
      end

      if params[:claim].present? && params[:claim][:invoice_receive].present?
        begin
          claim_date =  Date.strptime(params[:claim][:invoice_receive], '%m/%d/%Y')
        rescue
          claim_date =  Date.strptime(params[:claim][:invoice_receive], '%d/%m/%Y')
        end          
        if @claim.invoice_receive.present?
          if @claim.invoice_receive.strftime("%m/%d/%Y").to_s == claim_date.to_date.strftime("%m/%d/%Y").to_s
            params[:claim][:invoice_status]
          else
            params[:claim][:invoice_status] = "Received"
          end
        else
          params[:claim][:invoice_status] = "Received"
        end
      end
      @claim.update_attributes(params[:claim])
      if params[:claim].present? && params[:claim][:invoice_receive].present?
        begin
          invoice_receive = Date.strptime(params[:claim][:invoice_receive], '%m/%d/%Y').to_date
        rescue
          invoice_receive = Date.strptime(params[:claim][:invoice_receive], '%d/%m/%Y').to_date
        end
        @claim.update_attributes(:invoice_receive => invoice_receive)
      end
    end
    @claim.update_attributes(:updated_by => update_last_change_field)
    respond_to do |format|
      format.html{redirect_to "/admin/claims/edit/#{@claim.id}"}
      format.js
    end
  end

  def edit
    #unless current_account.role == "sales"
      @claim = Claim.find(params[:id])
      @customer = @claim.customer
      respond_to do |format|
        format.html{render :layout => "new_admin"}
        format.js
      end
    #else
    #  redirect_to "/admin/dashboard"
    #end
  end

  def add_claim_notes
    @claim = Claim.find(params[:id]) if params[:id].present? 
    if @claim.present? && params[:claim].present? && params[:claim][:note_text].present? or params[:claim].present? && params[:claim][:note_image].present?
      note_text = params[:claim][:note_text].scan(/.{1,100}/m).join(" ")
      note = @claim.notes.build(:note_text => note_text, :customer_id => @claim.customer_id, :agent_name => @current_account.parent.name)
      ## AWS - File Upload on Amazone S3
      note.attachments.build(:avatar => params[:claim][:note_image]) if params[:claim][:note_image].present?
      #note.attachments.build()
      note.save

      ## GOOGLE COULD
      #attach_file = "note_#{note.id}_#{params[:claim][:note_image].original_filename.strip.delete(' ')}"
      #file_path = File.join(Rails.root, 'public', 'images', 'upload_images', attach_file)
      #File.open(file_path, 'wb') do |f|
      #  f.write params[:claim][:note_image].read
      #end
      #$cloud_connection_client.insert_image_into_bucket('contractor_insured',attach_file,"#{file_path}","#{params[:claim][:note_image].content_type}")
      #n = note.attachments.build(:attach_url => attach_file) if params[:claim][:note_image].present?
      #n.save
      #File.delete(Rails.root + "public/images/upload_images/#{attach_file}")

    end
    redirect_to "/admin/claims/edit/#{@claim.id}"
  end

  def generate_pdf_for_buy_out
    @claim = Claim.find(params[:claim_id])
    require 'prawn'
    doc = Prawn::Document.new(:margin => [60, 60, 20, 60]) do |pdf|
      tos_font  = "#{Rails.root}/app/views/admin/customers/Arial Narrow.ttf"
      body_font = 'Helvetica'
      body_font_size  = 10

      pdf.image "#{Rails.root}/app/assets/images/logo.png", :height => 60, :kerning => true, :at => [10, 730]

      pdf.font_size = 15
      pdf.formatted_text_box [{:text => "REFUND AND RELEASE AGREEMENT", :styles => [:bold]}], :at => [200, 700]
      pdf.move_down 80
      pdf.font_size = 10
      pdf.text "<b>POLICY HOLDER </b>: #{@claim.customer.name}", :inline_format => true
      pdf.move_down 20
      pdf.formatted_text_box [{:text => "POLICY #: ", :styles => [:bold]}, { :text => "#{@claim.customer.contract_number}"}], :at => [0, 600]
      pdf.formatted_text_box [{:text => "CLAIM #: ", :styles => [:bold]}, {:text => "#{@claim.id}"}], :at => [200, 600]
      pdf.move_down 30
      pdf.text "<b>COVERAGE ADDRESS: </b> #{@claim.customer.properties.last.to_s}", :inline_format => true
      pdf.move_down 20
      pdf.text "PLEASE EMAIL THIS SIGNED AGREEMENT TO <link href='mailto:ra@selecthomewarranty.com'>ra@selecthomewarranty.com</link>", :align => :center,  :inline_format => true
      pdf.move_down 20
      pdf.font body_font, :style => :bold
      pdf.text "TO ALL TO WHOM THESE PRESENTS SHALL COME OR MAY CONCERN KNOW THAT:"
      pdf.move_down 20
      pdf.font body_font
      pdf.text "I <b><u> #{@claim.customer.name } </u></b> residing at <b><u>#{@claim.customer.properties.last.to_s}</u></b> as RELEASOR, for AGREED UPON SETTLEMENT IN THE AMOUNT OF <b> $ #{@claim.buyout_or_reimbursement_amount }</b> together with other good and valuable consideration received from <b> Select Home Warranty</b> with a principal place of business at 1 International Blvd Suite 400 Mahwah NJ 07495 referred to as RELEASEE, receipt of which is hereby acknowledged, releases and discharges the RELEASEE, RELEASEE'S heirs, executors, administrators, successors and assigns from all actions, causes of action, suits, debts, dues, sums of money, accounts, reckonings, bonds, bills, specialties, covenants, contracts, controversies, agreements, promises, variances, trespasses, damages, judgments, extents, executions, claims, and demands whatsoever, in law, admiralty or equity, which against the RELEASEE, the RELEASOR, RELEASOR'S heirs, executors, administrators, successors and assigns ever had, now have or hereinafter can shall or may, have for, upon, or by reason of any matter, cause or thing whatsoever from the beginning of the world to the day of the date of this RELEASE. This RELEASE may not be changed orally.", :align => :justify, :leading => 5, :inline_format => true
      pdf.move_down 15
      #pdf.text "<b> Recipient Information </b>", :inline_format => true
      pdf.text "<b> Please fill in address that check should be mailed too </b>", :inline_format => true
      pdf.font_size = 9
      pdf.move_down 10
      #pdf.text "<b>Name : </b><u> #{@claim.customer.name}</u>", :inline_format => true

      pdf.formatted_text_box [{:text => "Name : "},{:text => "__________________", :styles => [:underline]}], :at => [0, 240]
      pdf.formatted_text_box [{:text => "IN WITNESS WHEREOF, the RELEASOR has hereunto set RELEASOR'S hand and seal on the ____________ day of__________, __________."}], :at => [230, 240]

      pdf.move_down 35
      pdf.text "Address : ____________________________"
      pdf.move_down 5
      pdf.text "City :______________ State : ______________"
      pdf.move_down 5
      pdf.text "Zip Code: _______________________"
      pdf.move_down 20
      pdf.font body_font
      #pdf.text "IN WITNESS WHEREOF, the RELEASOR has hereunto set RELEASOR'S hand and seal on the ____________ day of__________, __________.", :leading => 5, :inline_format => true
      pdf.move_down 50
      pdf.formatted_text_box [{:text => "_______________________"}], :at => [0, 140]
      pdf.formatted_text_box [{:text => "_______________________"}], :at => [200, 140]
      pdf.formatted_text_box [{:text => "_____________"}], :at => [400, 140]
      pdf.formatted_text_box [{:text => "POLICY HOLDER (PRINT)"}], :at => [0, 120]
      pdf.formatted_text_box [{:text => "POLICY HOLDER(SIGNATURE)"}], :at => [200, 120]
      pdf.formatted_text_box [{:text => "DATE"}], :at => [400, 120]
      pdf.move_down 100
      # pdf.text "PLEASE ALLOW 7-21 BUSINESS DAYS TO RECEIVE YOUR PAYMENT", :align => :center 
      pdf.text "PLEASE ALLOW UP TO 30 DAYS TO RECEIVE YOUR PAYMENT.", :align => :center 

    end        
    send_data(doc.render, :filename => "buyout", :type => "application/pdf")
  end

end
