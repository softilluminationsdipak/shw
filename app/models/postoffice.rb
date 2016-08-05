require 'net/http'
require 'net/https' # You can remove this if you don't need HTTPS
require 'uri'

class Postoffice < ActionMailer::Base
  
  def message_(recipients, subject, message, inspect='')
    @message = message
    @inspect = inspect
    mail(:to => recipients,
         :from => $installation.noreply_email,
         :subject => subject)
  end
  
  def template(template_id, recipients, data=nil,reply_to_address_option=nil)
    template = nil
    if template_id.to_i == 0
  	template = EmailTemplate.find_by_name(template_id)
    else
    	template = EmailTemplate.find(template_id)
    end
    raise "Could not find Email Template: #{template_id}" unless template
    template.data = data
    @et = template

    begin
      if data and data[:attachments]
          # Rails interprets JSON arrays as hashes with string indices of numbers
          data[:attachments].each { |i, hash|
          attachments[hash[:filename]] = {
            :content_type  => hash[:content_type],
            :body          => File.read("#{Rails.root}/#{hash[:path]}/#{hash[:filename]}")
          }
        }
      end
      # check attachment of pdf file
      # ==================================================================================
      template.parse_attachments # check attachment fields, like contract_pdf attach placeholder

      customer_id = data[:customer].id
      if template.is_contract_pdf_attachable?
        puts "contract_pdf attachment...."
        contract_pdf_file_path = "#{Rails.root}/contracts/contract_#{customer_id}.pdf"
        # check file existance, and not, then render pdf and save as file
        # unless File.exists?(contract_pdf_file_path)

        # always render pdf file, for latest contract
        contract_pdf_file_created =Customer.find(customer_id).save_contract_pdffile #GetAttachPdf::save_contract_pdffile(customer_id)
        # else
        #  contract_pdf_file_created = true
        #end
        # prepare attachment file name
        #if customer_id.to_i >= 100000
        #  attach_file_name= "#{$installation.invoice_prefix2}#{customer_id}_CONTRACT_#{data[:customer].first_name[0]}#{data[:customer].last_name}_#{Time.now.strftime("%m%d%Y")}.pdf"
        #else
          attach_file_name= "#{$installation.invoice_prefix}#{customer_id}_CONTRACT_#{data[:customer].first_name[0]}#{data[:customer].last_name}_#{Time.now.strftime("%m%d%Y")}.pdf"
        #end

        # and attach
        if contract_pdf_file_created
           attachments[attach_file_name]=File.read("#{Rails.root}/contracts/contract_#{customer_id}.pdf")
        end
      end

      if template.is_work_order_pdf_attachable?
        puts "workorder_pdf attachment....."
        repair_id = data[:repair].id rescue 0

        if repair_id != 0
          work_order_created = GetAttachPdf.work_order_file(repair_id)
          #if customer_id.to_i >= 100000
          #  attach_file_name = "#{$installation.invoice_prefix2}#{customer_id}_WORKORDER_#{data[:customer].first_name[0]}#{data[:customer].last_name}_#{Time.now.strftime("%m%d%Y")}.pdf"
          #else
            attach_file_name = "#{$installation.invoice_prefix}#{customer_id}_WORKORDER_#{data[:customer].first_name[0]}#{data[:customer].last_name}_#{Time.now.strftime("%m%d%Y")}.pdf"
          #end

          if work_order_created == true
            claim_number = Repair.find(repair_id).claim.claim_number
            attachments[attach_file_name] = File.read("#{Rails.root}/contracts/workorder_#{claim_number}.pdf")
          end
        end
      end

      if template.is_performa_invoice_pdf_attachable?
        # [TODO] performa invoice pdf attachment
      end
      # ===================================================================================

    rescue  # Rescue from and ignore problems attaching so the email at least is delivered
      logger.info("Could not attach to email:\n#{$!.message}")
    end

    # get reply_to option of template
    reply_to_address = template.reply_to
    from_address = template.name.to_s.downcase == "welcome" ? $installation.noreply_email_contact : $installation.noreply_email
    if !(reply_to_address.nil?)
      mail(:to => recipients,
         :from => from_address, 
         :subject => template.parsed_subject,
	 :reply_to => reply_to_address)
    else
      mail(:to => recipients,
         :from => $installation.noreply_email,
         :subject => template.parsed_subject)
    end
  end
end
