namespace :shw do
  desc "all records before 3/3/14 that status new that convert to left message"
  task :convert_new_to_left_message => :environment do
    puts("======WAIT FOR A MINUT...====")
    c = Customer.where("DATE(created_at) <= ? AND status_id = ?", "9/3/2014".to_date, 0)
    puts("=====Total No. of Record for New Status and Date is Less Than 9/3/2014: #{c.count}=====Format DD/MM/YYYY==============")
    c.each do |customer|
      puts("=BEFORE=====Customer Information :> ====Customer ID : => #{customer.id} === Customer Created At : => #{customer.created_at} === Status => #{customer.status} ===================")
      #if customer.update_attributes(:status_id => 1)
      customer.status_id = 1
      customer.save(:validate => false)  
      puts("=AFTER=====Customer Information :> ====Customer ID : => #{customer.id} === Customer Created At : => #{customer.created_at} === Status => #{customer.status} ====================")
      #else
      #  puts("===Error => #{customer.errors.full_messages }================")
      #end
    end
    puts("======Hurry...It's done...====")
  end

  desc "Add Discount Codes"
  task :add_old_discount_code => :environment do
    puts("======WAIT FOR A MINUT...====")
    Partner.all.each do |p|
      p.update_attributes(:discount_code => p.auth_token[0..5])
    end
    puts("======Hurry...It's done...====")    
  end

  desc "Find Discount Code"
  task :find_discount_code => :environment do
    puts "=========================="
    Discount.all.each do |d|
      puts "============#{d.name}=============="
    end
  end

  desc "Add Default Customer Status"
  task :add_customer_status => :environment do 
    puts("======WAIT FOR A MINUT...====")
    CustomerStatus.delete_all
    CustomerStatus.create(:csid => 0, :customer_code => "New", :customer_status => "New", :active => true, :navigation => true, :color_code => "ffffff", :status_url => "/admin/customers/list/new")
    CustomerStatus.create(:csid => 1, :customer_code => "LM", :customer_status => "Left Message", :active => true, :navigation => true, :color_code => "ffffff", :status_url => "/admin/customers/list/leftmessage")
    CustomerStatus.create(:csid => 2, :customer_code => "DEL", :customer_status => "Deleted", :active => true, :navigation => true, :color_code => "ffffff", :status_url => "/admin/customers/list/deleted")
    CustomerStatus.create(:csid => 3, :customer_code => "FU", :customer_status => "Follow up", :active => true, :navigation => true, :color_code => "ffffff", :status_url => "/admin/customers/list/followup")
    CustomerStatus.create(:csid => 4, :customer_code => "CO", :customer_status => "Completed Order", :active => true, :navigation => true, :color_code => "ffffff", :status_url => "/admin/customers/list/completedorder")
    CustomerStatus.create(:csid => 5, :customer_code => "PRO", :customer_status => "Proforma", :active => true, :navigation => true, :color_code => "ffffff", :status_url => "/admin/customers/list/proforma")
    CustomerStatus.create(:csid => 6, :customer_code => "TBB", :customer_status => "To Be Billed", :active => true, :navigation => true, :color_code => "ffffff", :status_url => "/admin/customers/list/tobebilled")
    CustomerStatus.create(:csid => 7, :customer_code => "CAN", :customer_status => "Cancelled", :active => true, :navigation => true, :color_code => "ffffff", :status_url => "/admin/customers/list/cancelled")
    CustomerStatus.create(:csid => 8, :customer_code => "RREF", :customer_status => "Requested Refund", :active => true, :navigation => true, :color_code => "ffffff", :status_url => "/admin/customers/list/request_refund" )
    CustomerStatus.create(:csid => 9, :customer_code => "2BREF", :customer_status => "To Be Refunded", :active => true, :navigation => true, :color_code => "ffffff", :status_url => "/admin/customers/list/to_be_refund")
    CustomerStatus.create(:csid => 10, :customer_code => "DECL", :customer_status => "Declined", :active => true, :navigation => true, :color_code => "ffffff", :status_url => "/admin/customers/list/declined")
    CustomerStatus.create(:csid => 11, :customer_code => "EMAIL", :customer_status => "Email List", :active => true, :navigation => true, :color_code => "ffffff", :status_url => "/admin/customers/list/email_list" )
    CustomerStatus.create(:csid => 12, :customer_code => "DNC", :customer_status => "Do Not Call", :active => true, :navigation => true, :color_code => "ffffff", :status_url => "/admin/customers/list/do_not_call")
    CustomerStatus.create(:csid => 13, :customer_code => "DIS", :customer_status => "Disconnected", :active => true, :navigation => true, :color_code => "ffffff", :status_url => "/admin/customers/list/disconnected")
    CustomerStatus.create(:csid => 14, :customer_code => "RENREF", :customer_status => "Refused Renewal", :active => true, :navigation => true, :color_code => "ffffff", :status_url => "/admin/customers/list/refused_renewal")
  end

  desc "Add Default Claim Status"
  task :add_claim_status => :environment do
    puts("======WAIT FOR A MINUT...====")
    ClaimStatus.delete_all
    ClaimStatus.create(:csid => 0, :claim_code => "NotSet", :claim_status => "Not Set", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    ClaimStatus.create(:csid => 1, :claim_code => "PlacedAgnt", :claim_status => "Placed by Agent", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    ClaimStatus.create(:csid => 2, :claim_code => "PlacedCust", :claim_status => "Placed by Customer", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    ClaimStatus.create(:csid => 3, :claim_code => "ContractWait", :claim_status => "Waiting for Contract", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    ClaimStatus.create(:csid => 4, :claim_code => "Disp", :claim_status => "Contractor Dispatched", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    ClaimStatus.create(:csid => 5, :claim_code => "Reported", :claim_status => "Contractor Reported", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    ClaimStatus.create(:csid => 6, :claim_code => "Aprvd", :claim_status => "Approved", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    ClaimStatus.create(:csid => 7, :claim_code => "Denied", :claim_status => "Denied", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    ClaimStatus.create(:csid => 8, :claim_code => "MoreInfo", :claim_status => "Need More Info.", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    ClaimStatus.create(:csid => 9, :claim_code => "Contacted", :claim_status => "Customer Contacted", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    ClaimStatus.create(:csid => 10, :claim_code => "SndRelease", :claim_status => "Send Release", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    ClaimStatus.create(:csid => 11, :claim_code => "RcvdRelease", :claim_status => "Received Release", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    ClaimStatus.create(:csid => 12, :claim_code => "Paid", :claim_status => "Paid", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    ClaimStatus.create(:csid => 13, :claim_code => "ReDisp", :claim_status => "Re-Dispatched", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    ClaimStatus.create(:csid => 14, :claim_code => "PicWait", :claim_status => "Waiting for pics", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    ClaimStatus.create(:csid => 15, :claim_code => "Ineffective", :claim_status => "Ineffective", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    ClaimStatus.create(:csid => 16, :claim_code => "InProgress", :claim_status => "In Progress", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    ClaimStatus.create(:csid => 17, :claim_code => "Ready2Report", :claim_status => "Ready To Report", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    ClaimStatus.create(:csid => 18, :claim_code => "Ready2Dispatch", :claim_status => "Ready To Dispatch", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    ClaimStatus.create(:csid => 19, :claim_code => "NeedInfoCustomer", :claim_status => "NeedInfoCustomer", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    ClaimStatus.create(:csid => 20, :claim_code => "GoodReview", :claim_status => "GoodReview", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    ClaimStatus.create(:csid => 21, :claim_code => "ThreatenedAction", :claim_status => "ThreatenedAction", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    ClaimStatus.create(:csid => 22, :claim_code => "R2RRita", :claim_status => "R2R Rita", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    ClaimStatus.create(:csid => 23, :claim_code => "R2RVadim", :claim_status => "R2R Vadim", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    ClaimStatus.create(:csid => 24, :claim_code => "R2RRick", :claim_status => "R2R Rick", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    ClaimStatus.create(:csid => 25, :claim_code => "SendCheck", :claim_status => "Send Check", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
  end

  desc "Add Default Lead Status"
  task :add_lead_status => :environment do
    puts("======WAIT FOR A MINUT...====")
    LeadStatus.delete_all
    LeadStatus.create(:csid => 1, :lead_code => "WARM", :lead_status => "warm", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    LeadStatus.create(:csid => 2, :lead_code => "SOLD", :lead_status => "sold", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    LeadStatus.create(:csid => 3, :lead_code => "DEAD", :lead_status => "dead", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
  end

  desc "Add Default Result Status"
  task :add_result_status => :environment do
    puts("======WAIT FOR A MINUT...====")
    ResultStatus.delete_all
    ResultStatus.create(:csid => 1, :result_code => "YES", :result_status => "Yes", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    ResultStatus.create(:csid => 2, :result_code => "NO", :result_status => "No Interest", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    ResultStatus.create(:csid => 3, :result_code => "CB", :result_status => "Callback", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    ResultStatus.create(:csid => 4, :result_code => "NC", :result_status => "No Contact", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    ResultStatus.create(:csid => 5, :result_code => "LM", :result_status => "Left Message", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    ResultStatus.create(:csid => 6, :result_code => "VM", :result_status => "Voice Mail", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    ResultStatus.create(:csid => 7, :result_code => "EMAIL", :result_status => "Email Sent", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    ResultStatus.create(:csid => 8, :result_code => "BZ", :result_status => "Busy Signal", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    ResultStatus.create(:csid => 9, :result_code => "W#", :result_status => "Wrong#/Disconnected", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    ResultStatus.create(:csid => 10, :result_code => "DNC", :result_status => "Do Not Call", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
  end

  desc "Add Default Tag Status"
  task :add_task_status => :environment do
    puts("======WAIT FOR A MINUT...====")
    TagStatus.delete_all
    TagStatus.create(:csid => 1, :tag_code => "TST", :tag_status => "Test Tag", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")    
    TagStatus.create(:csid => 2, :tag_code => "TST2", :tag_status => "Test Tag 2", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")    
  end

  desc "Add Default Contract Status"
  task :add_contract_status => :environment do
    puts("======WAIT FOR A MINUT...====")
    ContractStatus.delete_all
    ContractStatus.create(:csid => 1, :contract_code => "CO",    :contract_status => "Completed Order", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    ContractStatus.create(:csid => 2, :contract_code => "PRO",   :contract_status => "Proforma",        :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    ContractStatus.create(:csid => 3, :contract_code => "TBB",   :contract_status => "To Be Billed",    :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    ContractStatus.create(:csid => 4, :contract_code => "CAN",   :contract_status => "Cancelled",       :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    ContractStatus.create(:csid => 5, :contract_code => "RREF",  :contract_status => "Request Refund",  :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    ContractStatus.create(:csid => 6, :contract_code => "2BREF", :contract_status => "To Be Refunded",  :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
  end

  desc "Add Default Renewal Status"
  task :add_renewal_status => :environment do
    puts("======WAIT FOR A MINUT...====")
    RenewalStatus.delete_all
    RenewalStatus.create(:csid => 1, :renewal_code => "REN90",    :renewal_status => "Renews in 90 Days", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    RenewalStatus.create(:csid => 2, :renewal_code => "REN60",    :renewal_status => "Renews in 60 Days", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    RenewalStatus.create(:csid => 3, :renewal_code => "REN30",    :renewal_status => "Renews in 30 Days", :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    RenewalStatus.create(:csid => 4, :renewal_code => "RENOD",    :renewal_status => "Renewal Overdue",   :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
    RenewalStatus.create(:csid => 5, :renewal_code => "RENREF",   :renewal_status => "Refused Renewal",   :status_url => "", :active => true, :navigation => true, :color_code => "ffffff")
  end


  #desc "Common task for all status"
  #task :all => [ :add_renewal_status, :add_contract_status, :add_task_status, :add_result_status, :add_lead_status, :add_claim_status,  :add_customer_status ]
  #Rake::Task["all"].invoke
  desc "Update Duplicate Records"
  task :change_duplicate_records_status_with_delete => :environment do
    Customer.where("status_id != ?", 2).each do |t|
      customers = Customer.where("status_id != ?", 2).where("email = ?", t.email)
      if customers.count > 1
        customers.each do |s|
          s.status_id = 2
          s.save
        end
      end
    end
  end

end