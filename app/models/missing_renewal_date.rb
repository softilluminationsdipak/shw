class MissingRenewalDate < ActiveRecord::Base
  attr_accessible :cdate, :customer_id, :customer_state, :fullname, :no_of_transaction, :total

  def self.to_csv4(options = {})
    CSV.generate(options) do |csv|
      csv << ["CustomerId", "Fullname", "Customer State", "NumOfPayments", "Total", "CreatedDate"]
      all.each do |customer|
        #csv << [customer.id, customer.cust_fullname, customer.cust_state, customer.transactions.count, customer.total_transaction_amount, customer.created_at.strftime("%m/%d/%Y")] 
        # csv << [customer.customer_id, customer.fullname, customer.customer_state, customer.no_of_transaction, "$ #{customer.total}", customer.cdate.strftime("%m/%d/%Y")] 
        csv << [customer.customer_id, "#{customer.fullname}", "#{customer.customer_state}", "#{customer.no_of_transaction}", "$ #{customer.total}", "#{customer.cdate}" ] 
      end
    end
  end

end
