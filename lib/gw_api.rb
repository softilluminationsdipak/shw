require 'rubygems'
require 'curb'
require 'uri'
require 'addressable/uri'

class GwApi
  def initialize()
    @login = {}
    @order = {}
    @billing = {}
    @shipping = {}
    @responses = {}
  end

  def setLogin(username,password)
    @login['password'] = password
    @login['username'] = username
  end

  def setOrder( orderid, orderdescription, tax, shipping, ponumber,ipadress)
    @order['orderid'] = orderid;
    @order['orderdescription'] = orderdescription
    @order['shipping'] = "%.2f" % shipping
    @order['ipaddress'] = ipadress
    @order['tax'] = "%.2f" % tax
    @order['ponumber'] = ponumber
  end

  def setBilling(firstname, lastname, company, address1, address2, city, state, zip, country, phone, fax, email, website)
    @billing['firstname'] = firstname
    @billing['lastname']  = lastname
    @billing['company']   = company
    @billing['address1']  = address1
    @billing['address2']  = address2
    @billing['city']      = city
    @billing['state']     = state
    @billing['zip']       = zip
    @billing['country']   = country
    @billing['phone']     = phone
    @billing['fax']       = fax
    @billing['email']     = email
    @billing['website']   = website
  end

  def setShipping(firstname, lastname, company, address1, address2, city, state, zipcode, country, email)
    @shipping['firstname'] = firstname
    @shipping['lastname']  = lastname
    @shipping['company']   = company
    @shipping['address1']  = address1
    @shipping['address2']  = address2
    @shipping['city']      = city
    @shipping['state']     = state
    @shipping['zip']       = zipcode
    @shipping['country']   = country
    @shipping['email']     = email
  end

  def doSale(amount, ccnumber, ccexp, cvv='', merchant_account)
    query  = ""
    # Login Information
    query = query + "username=" + URI.escape(@login['username']) + "&"
    query += "password=" + URI.escape(@login['password']) + "&"
    # Sales Information
    query += "ccnumber=" + URI.escape(ccnumber) + "&"
    query += "ccexp=" + URI.escape(ccexp) + "&"
    query += "amount=" + URI.escape("%.2f" %amount) + "&"
    if (cvv!='')
      query += "cvv=" + URI.escape(cvv) + "&"
    end
    # Order Information
    @order.each do | key,value|
      query += key +"=" + URI.escape(value) + "&"
    end
    # Billing Information
    @billing.each do | key,value|
      query += key +"=" + URI.escape(value) + "&"
    end
    # Shipping Information
    @shipping.each do | key,value|
      query += key +"=" + URI.escape(value) + "&"
    end
    query += 'processor_id=' + merchant_account.merchant_name + '&'
    query += "type=sale"
    return doPost(query)
  end

  def cancelSubscription(subscription_id)
    query = ''
    query = query + "username=" + URI.escape(@login['username']) + "&"
    query += "password=" + URI.escape(@login['password']) + "&"
    query += 'recurring=' + 'delete_subscription' + '&'
    query += 'subscription_id=' + subscription_id
    return doPost(query)
  end

  def refund(transaction_id, amount)
    query = ''
    query = query + "username=" + URI.escape(@login['username']) + "&"
    query += "password=" + URI.escape(@login['password']) + "&"
    query += 'type=' + 'refund' + '&'
    query += 'transactionid=' + transaction_id + '&'
    query += 'amount=' + amount
    return doPost(query)
  end

  def doVoid(transaction_id)
    query = ''
    query = query + "username=" + URI.escape(@login['username']) + "&"
    query += "password=" + URI.escape(@login['password']) + "&"
    query += 'type=' + 'void' + '&'
    query += 'transactionid=' + transaction_id + '&'
    return doPost(query)
  end

  def doSale2(amount, ccnumber, ccexp, cvv='', customer, start_date, end_date, merchant_account)
    query  = ""
    # Login Information
    query = query + "username=" + URI.escape(@login['username']) + "&"
    query += "password=" + URI.escape(@login['password']) + "&"
    # Sales Information
    query += "ccnumber=" + URI.escape(ccnumber) + "&"
    query += "ccexp=" + URI.escape(ccexp) + "&"
    query += "amount=" + URI.escape("%.2f" %amount) + "&"
    if (cvv!='')
      query += "cvv=" + URI.escape(cvv) + "&"
    end
    # Order Information
    @order.each do | key,value|
      query += key +"=" + URI.escape(value) + "&"
    end
    # Billing Information
    @billing.each do | key,value|
      query += key +"=" + URI.escape(value) + "&"
    end
    # Shipping Information
    @shipping.each do | key,value|
      query += key +"=" + URI.escape(value) + "&"
    end
    query += "type=sale" + "&"

    # Custom Subscription
    
    query += "plan_payments=" + "#{customer.pay_amount}" + "&"
    query += "plan_amount=" + "#{customer.pay_amount.to_f * customer.num_payments.to_i}" + "&"
    # query += "plan_name=" + "customer_#{customer_id}" + "&"
    # query += "plan_id=" + "#{customer_id}" + "&"
    query += "month_frequency=" + "#{customer.num_payments}" + "&"
    query += "day_of_month=" + '1' + '&'
    query += 'payment=' + 'creditcard' + '&'
    if start_date.present?
      query += "start_date=" + "#{start_date.strftime('%Y%m%d')}" + '&'
    end
    if end_date.present?
      # query += 'end_date=' + "#{end_date.strftime('%Y%m%d')}" + '&'
    end
    query += 'processor_id=' + merchant_account.merchant_name + '&'
    query += "recurring="  + 'add_subscription'
    return doPost(query)
  end


  def doPost(query)
    curlObj = Curl::Easy.new("https://secure.networkmerchants.com/api/transact.php")
    curlObj.connect_timeout = 15
    curlObj.timeout = 15
    curlObj.header_in_body = false
    curlObj.ssl_verify_peer=false
    curlObj.post_body = query
    curlObj.perform()
    data = curlObj.body_str

    # NOTE: The domain name below is simply used to create a full URI to allow URI.parse to parse out the query values
    # for us. It is not used to send any data
    data = '"https://secure.networkmerchants.com/api/transact.php?' + data
    uri = Addressable::URI.parse(data)
    @responses = uri.query_values
    return @responses['response']
  end

  def getResponses()
    return @responses
  end
end