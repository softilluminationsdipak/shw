class Admin::SubscriptionsController < ApplicationController
	
	before_filter :check_login
	def nmi_billing
		@customer = Customer.find(params[:id])
		if params[:subscription][:credit_card_id].present?  && params[:subscription][:amount].present? && params[:subscription][:start_date].present?
			params[:subscription][:start_date] = Date.strptime(params[:subscription][:start_date], '%m/%d/%Y')
			@card = CreditCard.find(params[:subscription][:credit_card_id])
			amount = params[:subscription][:amount].to_f
			if amount.to_f >= 1.0
				nmi_charge(@card, amount, params)
			else
				response = {responsetext: 'you entered amount is less then 1.0', response: 3}
			end		
		else
			response = {responsetext: 'Invalid Parameters', response: 3}
		end			
		@response = response
		respond_to do |format|
			format.html{redirect_to "/admin/customers/nmi_payment/#{params[:id]}"}
			format.js{}
		end		
	end

	def manual_billing
		@customer = Customer.find(params[:id])
		if params[:manual][:credit_card_id].present? && params[:manual][:amount].present?
			@card = CreditCard.find(params[:manual][:credit_card_id])
			amount = params[:manual][:amount].to_f
			if amount.to_f >= 1.0
				nmi_charge(@card, amount, params)
			else
				response = {responsetext: 'you entered amount is less then 1.0', response: 3}
			end		
		else
			response = {responsetext: 'Invalid Parameters', response: 3}
		end			
		@response = response
		respond_to do |format|
			format.html{redirect_to "/admin/customers/nmi_payment/#{params[:id]}"}
			format.js{}
		end		
	end

  def async_get_for_customer
    subscriptions = Subscription.of_customer(params[:id])
    render :json => subscriptions.collect { |t|
      {
        :date => with_timezone(t.created_at).strftime("%m/%d/%y %I:%M %p"),
        :start_date => t.sdate.strftime("%m/%d/%y"),
        :amount => "$%5.2f" % t.amount,
        :my_interval => t.sub_interval,
        :status => t.is_cancel_subscription.present? ? "#{t.status}-(Can)" : "#{t.status}",
        :occurance => t.occurances,
        :credit_card_id => t.credit_card_id,
        :credit_card => t.credit_card.present? ? t.credit_card.cc_with_last_4 : '',
        :id => t.id,
        :subscription_id => t.transaction.present? ? t.transaction.subscriptionid : nil,
        :is_cancel_subscription => t.is_cancel_subscription,
        :isCancelSubscription => t.isCancelSubscription,
        :isActiveSubscription => t.isActiveSubscription,
        :no_end_date => t.no_end_date,
        :end_date => t.sub_end_date

      }
    }
  end

  def delete_subscription
  	@subscription = Subscription.find(params[:id])
  	@customer = Customer.find(@subscription.customer_id)
    nmi = GwApi.new()
    nmi.setLogin("demo", "password");
    nmi.cancelSubscription("#{@subscription.transaction.subscriptionid}")
    nmi_res = nmi.getResponses
    if (nmi_res['response'] == '1')
       @subscription.is_cancel_subscription = true
       @subscription.save       
    end 
    @customer.notes.create(:note_text => nmi_res['responsetext']) 	
  	redirect_to "/admin/customers/nmi_payment/#{@customer.id}"
  end

  def refund
  	@transaction = Transaction.find(params[:id])
  	@customer = Customer.find(@transaction.customer_id)
    nmi = GwApi.new()
    #nmi.setLogin("demo", "password");
    gateway = Gateway.first

    merchant_account = Subscription.nmi_login(@customer.state)
    if merchant_account.present?
      #nmi.setLogin(merchant_account.username, merchant_account.password);
      nmi.setLogin(gateway.login_id, gateway.password)    
      if params[:amount].present? && params[:amount].to_f >= 0.0 #&& params[:amount].to_i <= @transaction.amount.to_i && (@transaction.refund.to_f + params[:amount].to_f) <= @transaction.amount.to_f
        nmi.refund("#{@transaction.transactionid}", "#{params[:amount]}")
        nmi_res = nmi.getResponses
        if (nmi_res['response'] == '1')
        	# Do Process here
        	@transaction.update_attributes(:refund => @transaction.refund.to_f + params[:amount].to_f )          
          note = Note.create({
            :customer_id => @customer.id,
            :note_text => "Refund of $#{params[:amount].to_f} for Transaction ##{@transaction.id}",            
            :agent_name => current_account.parent.name,
            :author_id => current_account.parent.id
          })        
        end 
        @customer.notes.create(:note_text => nmi_res['responsetext']) 	
      	redirect_to "/admin/customers/edit/#{@customer.id}", notice: "#{nmi_res['responsetext']}"
      else
        note = Note.create({
          :customer_id => @customer.id,
          :note_text => "Invalid Amount - $#{params[:amount].to_f} for Transaction ##{@transaction.id}",
          :agent_name => current_account.parent.name,
          :author_id => current_account.parent.id
        })                
        redirect_to "/admin/customers/edit/#{@customer.id}#billing", :notice => 'Invalid Amount'
      end
    end
  end

  def bill_manual_nmi
    amount = params[:amount].to_f
    @card = CreditCard.find(params[:id])    
    response = @card.charge_cents3!(amount * 100.0, params) if amount > 0.0
    if response && response['response'].to_s == "1"
      note = Note.create({
        :customer_id => @card.customer_id,
        :note_text => "Billed $%.2f to card ending in #{@card.last_4}." % amount,
        :agent_name => current_account.parent.name,
        :author_id => current_account.parent.id
      })
      notify(Notification::CREATED, { :message => 'created', :subject => note })
    else
      reason = response ? ", but it failed because: #{response['responsetext']}." : '.'
      note = Note.create({
        :customer_id => @card.customer.id,
        :note_text => "Attempted to bill $%.2f to card ending in #{@card.last_4}#{reason}" % amount,
        :agent_name => current_account.parent.name,
        :author_id => current_account.parent.id
      })
      notify(Notification::CREATED, { :message => 'created', :subject => note })
    end
    render :json => response ? response : nil
  end

  def bill_subscription_nmi
    amount = params[:amount].to_f
    @card = CreditCard.find(params[:id]) 
    if params[:no_end_date].present? && params[:no_end_date].to_s == 'false' && params[:end_date].to_s == ''
      response = {'response' => 0, 'responsetext' => 'Invalid End Date', 'authcode' => '000'}
    else
      response = @card.charge_cents2!(amount * 100.0, params) if amount > 0.0
      if response && response['response'].to_s == "1"
        note = Note.create({
          :customer_id => @card.customer_id,
          #:note_text => "Billed $%.2f to card ending in #{@card.last_4}." % amount,
          :note_text => "Subscription successfully created of $%.2f to card ending in #{@card.last_4}." % amount,
          :agent_name => current_account.parent.name,
          :author_id => current_account.parent.id
        })
        notify(Notification::CREATED, { :message => 'created', :subject => note })
      else
        reason = response ? "#{response['responsetext']}." : '.'
        note = Note.create({
          :customer_id => @card.customer.id,
          :note_text => "#{reason}",
          :agent_name => current_account.parent.name,
          :author_id => current_account.parent.id
        })
        notify(Notification::CREATED, { :message => 'created', :subject => note })
      end
    end
    render :json => response ? response : nil
  end

  def del_subscription ## response wia json
    @subscription = Subscription.find(params[:id])
    @customer = Customer.find(@subscription.customer_id)
    nmi = GwApi.new()
    merchant_account = Subscription.nmi_login(@customer.state)
    if merchant_account.present?
      #nmi.setLogin(merchant_account.username, merchant_account.password);
      gateway = Gateway.first
      nmi.setLogin(gateway.login_id, gateway.password)

      if @subscription.transaction.present? && @subscription.transaction.subscriptionid.present?
        nmi.cancelSubscription("#{@subscription.transaction.subscriptionid}")
        nmi_res = nmi.getResponses
        if (nmi_res['response'] == '1')
          @subscription.is_cancel_subscription = true
          @subscription.save
          Postoffice.template('Cancel Subscription', 'michael@softilluminations.com', {:customer => @customer, :subscription => @subscription}).deliver
        end 
        @customer.notes.create(:note_text => "#{nmi_res['responsetext']} for Subscription - #{@subscription.id}")   
      end
      if nmi_res.present? && nmi_res['responsetext'].present?
        notice_msg = nmi_res['responsetext']
      else
        notice_msg = 'Invalid Subscription ID'
      end
      redirect_to "/admin/customers/edit/#{@customer.id}#billing", notice: notice_msg
    else
      redirect_to "/admin/customers/edit/#{@customer.id}", :notice => "Invalid Credential for Merchant Account"
    end
  end

  def void_transaction
    transaction = Transaction.find(params[:transaction])
    customer = transaction.customer
    gw = GwApi.new()
    gateway = Gateway.first
    gw.setLogin(gateway.login_id, gateway.password)
    gw.doVoid(transaction.id)
    myResponses = gw.getResponses
    note = Note.create({
      :customer_id => @card.customer_id,
      :note_text => "Billed $%.2f to card ending in #{@card.last_4}." % amount,
      :agent_name => current_account.parent.name,
      :author_id => current_account.parent.id
    })
    redirect_to "/admin/customers/edit/#{customer.id}#billing"
  end

	private

	def nmi_charge(card, amount, params)
		@card = card
		param = params[:subscription].present? ? params[:subscription] : params[:manual]
		response = @card.charge_cents2!(amount * 100.0, param) if amount > 0.0
		if response && response['response'].to_s == "1"
			note = Note.create({
				:customer_id => @card.customer_id,
				:note_text => "Billed $%.2f to card ending in #{@card.last_4}." % amount,
				:agent_name => current_account.parent.name,
				:author_id => current_account.parent.id
			})
			notify(Notification::CREATED, { :message => 'created', :subject => note })
		else
			reason = response ? ", but it failed because: #{response['responsetext']}." : '.'
			note = Note.create({
				:customer_id => @card.customer.id,
				:note_text => "Attempted to bill $%.2f to card ending in #{@card.last_4}#{reason}" % amount,
				:agent_name => current_account.parent.name,
				:author_id => current_account.parent.id
			})
			notify(Notification::CREATED, { :message => 'created', :subject => note })
		end
		return response		
	end
end
