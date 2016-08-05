class Admin::RepairsController < ApplicationController
  before_filter :check_login
  #before_filter :only_admin_access, except: [:work_order]
  before_filter :check_permissions
#FIXME  contractor_can :index, :complete
  layout 'admin', :except => :async_create_or_update_for_claim

  ssl_exceptions []
  
  def index
    @selected_tab = 'repairs'
    @repairs = current_account.parent.repairs
  end
  
  # rich text format
  def work_order_rtf
    repair = Repair.find(params[:id])
    
    contractor_company = repair.contractor.company
    contractor_phone = repair.contractor.phone
    contractor_fax = repair.contractor.fax
    dispatch_date = repair.created_at.in_time_zone(EST).strftime("%B %d, %Y EST")
    claim_number = repair.claim.claim_number
    problem = (repair.claim.claim_text || '').gsub(/\n/, "\\\n")
    policy_holder = repair.claim.customer.name
#    property = repair.claim.property
    property = repair.claim.customer.properties.first
    coverage_address = "#{property.address}\\\n#{property.city_state_zip}"
    customer_phone = repair.customer.customer_phone
    customer_cell = repair.customer.mobile_phone
    service_fee = repair.formatted_service_charge
    service_fee_text = repair.service_charge.to_i.to_english.titleize << ' Dollars'
    contractor_number =  repair.customer.contract_number
    rtf = File.read("#{Rails.root}/app/views/admin/content/work_order_template.rtf")
    rtf.gsub!(/#([A-Za-z0-9.$!_]+?)#/) { |cmd| eval($1) }
    send_data(rtf, { :filename => "Work Order for Customer #{claim_number}.rtf", :type => 'text/rtf' })
  end
  
  # pdf format
  def work_order

    repair = Repair.find(params[:id])
    
    if repair.contractor.present? && repair.contractor.company.present? 
      contractor_company = repair.contractor.company
    else
      contractor_company = " "
    end
    contractor_phone = repair.contractor.phone
    contractor_fax = repair.contractor.fax
    dispatch_date = repair.created_at.in_time_zone(EST).strftime("%B %d, %Y EST")
    claim_number = repair.claim.claim_number
    problem = (repair.claim.claim_text || '').gsub(/\n/, "\\\n")
    policy_holder = repair.claim.  customer.name
#    property = repair.claim.property
    property = repair.claim.customer.properties.first
    coverage_address = "#{property.address}\\\n#{property.city_state_zip}"
    customer_phone = repair.customer.customer_phone
    customer_cell = repair.customer.mobile_phone
    service_fee = repair.formatted_service_charge
    service_fee_text = repair.service_charge.to_i.to_english.titleize << ' Dollars'
    contractor_number =  repair.customer.contract_number
    contractor_id   = repair.contractor.contractor_id_with_cr
    claim_type = repair.claim.claim_type

require 'prawn'
    doc = Prawn::Document.new(:margin => [20, 20, 40, 20]) do |pdf|
      tos_font  = "#{Rails.root}/app/views/admin/customers/Arial Narrow.ttf"
      body_font = 'Helvetica'
      body_font_size  = 10
      table_font_size = 9.5

      # Head Title
      pdf.image "#{Rails.root}/app/assets/images/logo.png", :height => 60, :kerning => true, :at => [0, 750]

      pdf.font_size = body_font_size
      #pdf.font body_font, :style => :bold
      pdf.formatted_text_box [{:text => "Claims Work Order / Authorization Form", :styles => [:bold]}], :at => [378, 740]
      
      pdf.font_size = 10
      pdf.formatted_text_box [{:text => "1 International Blvd Suite 400, Mahwah, NJ 07495"}], :at => [345, 720]
      pdf.formatted_text_box [{:text => "TEL: 1-855-267-3532 | FAX: 1-732-490-6612"}], :at => [368, 705]
      pdf.formatted_text_box [{:text => "Email: invoices@selecthomewarranty.com"}], :at => [380, 690]

      pdf.font_size = body_font_size
      pdf.font body_font, :style => :bold
      #pdf.line_width = 0
      #title_data = [
       #         ['Select Home Warranty - Claims Work Order / Authorization Form'],
       #      ]

      #pdf.table(title_data,  :cell_style => {:border_width => 0, :size => 12, :padding => [3,3,3,3], :align => :center}, :column_widths => { 0 => 570 })

      # Head Address section
      #address_data = [
      #          ['1 International Blvd Suite 400, Mahwah, NJ 07495'],
      #          ['TEL: 1-855-267-3532 - FAX: 1-732-490-6612'],
      #          ['Email: invoices@selecthomewarranty.com']
      #       ]

      #pdf.table(address_data,
      #          :cell_style => {:border_width => 0, :size => 8, :padding => [1,3,1,3], :align => :center},
      #          :column_widths => { 0 => 570 })

      pdf.move_down 70

      # Draw table
      pdf.font_size = body_font_size
      pdf.font body_font
      pdf.line_width = 1

      data = [
              ['            SERVICE PROVIDER:'  , "<b>#{contractor_company}</b>"],
              ['      SERVICE PROVIDER TEL# :'  , contractor_fax.to_s.empty? ? "<b>#{contractor_phone}</b>" : "<b>#{contractor_phone} FAX:#{contractor_fax}</b>"],
              ['            CONTRACTOR ID:'  , "<b>#{contractor_id}</b>"],
              ['        '   , ' '],
              ['               DISPATCH DATE:'		, "#{dispatch_date}"],
              ['                     CLAIM #:',                  "#{claim_number}"],
              ['            REPORTED PROBLEM:'	, "#{claim_type}: #{problem}"],
              ['   '			, '   '],
              ['               POLICY HOLDER:'		, "#{policy_holder}"],
              ['                  CONTRACT #:'		, "#{contractor_number}"],
              ['            COVERAGE ADDRESS:'	, "#{coverage_address}"],
              ['                 TELEPHONE #:'		, "#{customer_phone}"],
              ['                 CELLPHONE #:'		, "#{customer_cell}"],

             ]

      top_table_height = 0
      pdf.table(data,
                :cell_style => {:border_width => 1, :size => table_font_size, :padding => [3,3,3,3],:inline_format => true},
                :column_widths => { 0 => 200, 1 => 370 }) do |table|
        table.column(0).style(:align => :right)
        top_table_height = table.height
      end
      # -------------------------------------------------------------------------

      pdf.move_down 25

      pdf.font_size = body_font_size
      pdf.font body_font


      pdf.text "<b><u>DO NOT COMPLETE ANY REPAIRS THAT TOTAL ABOVE $100.00    (ONE HUNDRED DOLLARS) WITHOUT APPROVAL FROM SELECT HOME WARRANTY.</u></b>",:inline_format => true
      pdf.move_down 10

      pdf.text "<b><u>IF THE GROSS TOTAL REPAIR AMOUNT    IS ABOVE $100.00 (ONE HUNDRED DOLLARS) THE AUTHORIZATION #, AMOUNT, AND CUSTOMER SIGNATURE SHOULD BE FILLED OUT.</u></b>",:inline_format => true
      pdf.move_down 10

      pdf.text "<b><u>FAX / EMAIL ALL SIGNED INVOICES AND PICTURE(S) OF THE UNIT(S) IN QUESTION TO THE FAX / EMAIL ABOVE.</u></b>",:inline_format => true
      pdf.move_down 12

      pdf.font body_font
      pdf.font_size = body_font_size -1

      pdf.text "<b>Service Providers</b> are responsible to collect the <b>#{service_fee}</b> (#{service_fee_text}) service call fee directly from the customer. The customer is aware of this fee. If the <b>gross total repair<sup>1</sup>  </b> estimate exceeds the authorization limit, the technician should call the Select Home Warranty Authorizations Department <b>before any repairs are done</b>.",:inline_format => true
      pdf.move_down 10

      pdf.text "If the technician finds a policy exception (code violation, improper installation, mismatched system, or malfunction as a result of anything other than normal wear and tear), call our Claims Authorization Department at <b>1-855-267-3532</b> for an authorization <b># before any repairs are done</b>.",:inline_format => true
      pdf.move_down 10

      pdf.text "Select Home Warranty does not cover the aforementioned policy exceptions, and needs to be made aware of these exceptions while the technician is on site so that Select Home Warranty can explain the contract coverage to the customer, thereby preventing delays in service and possible miscommunications. A Select Home Warranty Authorization Agent may refer the customer to the onsite technician for all non-covered repairs."
      pdf.move_down 10

      # <sup> 1,2 </sup>
      pdf.font_size = 6
      pdf.text_box "1,2", :at => [307,643-top_table_height]
      pdf.text_box "1,2", :at => [192,609-top_table_height]

      pdf.font body_font
      pdf.font_size = body_font_size -1

      author_form = Proc.new { |y|
        pdf.text_box "Authorization #:", :at => [0,y+8]  
        pdf.stroke_line [75,y, 255,y]
        pdf.text_box "Authorization Amount$:", :at => [290,y+8]
        pdf.stroke_line [396,y, 570,y]
      }

      author_form.call(405-top_table_height)

      signature_form = Proc.new { |y|
        # draw grid
=begin
        pdf.stroke_line [0,y+43, 570,y+43]
        pdf.stroke_line [0,y+15, 570,y+15]
        pdf.stroke_line [0,y, 570,y]

        pdf.stroke_line [0,y, 0,y+43]
        pdf.stroke_line [210,y, 210,y+43]
        pdf.stroke_line [210+18,y, 210+18,y+43]
        pdf.stroke_line [210+18+210,y, 210+18+210,y+43]
        pdf.stroke_line [210+18+210+18,y, 210+18+210+18,y+43]
        pdf.stroke_line [570,y, 570,y+43]
=end
        # draw text
        pdf.text_box "Print name", :at => [5,y+11]  
        pdf.text_box "Signature", :at => [233,y+11]
        pdf.text_box "Date", :at => [461,y+11]

        pdf.stroke_line [5,y+18, 200,y+18]
        pdf.stroke_line [233,y+18, 428,y+18]
        pdf.stroke_line [461,y+18, 560,y+18]
      }

      signature_form.call(340 - top_table_height)


      pdf.move_down 100
      pdf.font body_font, :style => :bold,:align => :center

      #pdf.text "<b><u>FAX / EMAIL ALL SIGNED INVOICES AND PICTURE(S) OF THE UNIT(S) IN QUESTION TO THE FAX / EMAIL ABOVE.</b></u>",:inline_format => true,:align => :center
      pdf.text "<b><u> DO NOT MAIL INVOICES - EMAIL OR FAX ONLY</b></u>",:inline_format => true,:align => :center
      pdf.move_down 5

      pdf.text "<b>THE CLAIMS AUTHORIZATION DEPT IS AVAILABLE DURING THE FOLLOWING TIMES:</b>",:inline_format => true,:align => :center
      pdf.text "<b>MONDAY - THURSDAY 9:30 AM - 7PM - FRIDAY 9:30AM-6PM - SATURDAY 11AM- 5PM</b>",:inline_format => true,:align => :center

      pdf.move_down 5

      pdf.text "<b>(CLOSED ON SUNDAYS) ALL TIMES ABOVE ARE EASTERN STANDARD TIME.</b>",:inline_format => true,:align => :center

      pdf.move_down 10
      pdf.font_size = 5

      pdf.text "______________________________",:inline_format => true
      pdf.move_down 2
      pdf.text "1. Gross total repair includes service call charges, service fees paid by homeowner, diagnosis, trip charges, parts, labor, and tax."
      pdf.text "2. The Accounts Payable Department must receive all invoices within 30 days of the original work order date to receive payment. Invoices not received within the above time frame will be forfeited."
      pdf.text "3. All claims include the first hour before labor rates apply."



    end

    send_data(doc.render,
              :filename => "Work Order for Customer #{claim_number}",
              :type => "application/pdf")

  end

  def async_toggle_status
    render :json => Repair.find(params[:id]).toggle_status!
  end
  
  def async_toggle_authorization
    render :json => Repair.find(params[:id]).toggle_authorization!
  end
  
  def async_unassign_contractor_for_claim
    claim = Claim.find(params[:id])
    if claim.repair
      contractor = claim.repair.contractor
      updated = claim.repair.update_attributes({:contractor_id => nil})
      notify(Notification::UPDATED, { :message => "unassigned from Claim on #{claim.customer.contract_number}", :subject => contractor }) if updated
    end
    render :json => claim
  end
  
  def complete
    @selected_tab = 'repairs'
    @repair = Repair.find(params[:id])
    if request.post?
      params[:note][:note_text] = "#{@repair.contractor.company}:\n#{params[:note][:note_text]}"
      @repair.claim.customer.notes.create(params[:note])
      @repair.update_attributes({ :status => 1 })
      notify(Notification::UPDATED, { :message => 'completed', :subject => @repair })
      redirect_to :action => 'index'
    end
  end
end
