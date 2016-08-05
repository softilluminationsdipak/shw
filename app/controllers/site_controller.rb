class SiteController < ApplicationController
  layout :installation_layout,:except => [:affiliate, :error]

  def installation_layout
    $installation.code_name
  end

  ssl_required  :quote, :purchase

  before_filter :internal_page, :except => [:index, :plans, :quote, :purchase, :error]

  def http_options
    render :nothing => true, :status => 200
  end

  def _check
    render :text => Customer.count
  end

  def realestate
    redirect_to "/realestate"
  end

  def buyingandselling
    redirect_to "/buyingandselling"
  end

  def plans
    @page_title         = "Coverage Plans"
    @optional_coverages = Coverage.where(:optional => true).collect(&:coverage_name).in_groups(3)
  end

  def submitclaim
    @page_title     = "Contractor Helpdesk"
    @content_class  = "get-quote-page" # TODO: Rename to full-width
  end

  def homeownercenter
    redirect_to "/homeownercenter"
  end

  def contractors
    redirect_to "/contractors"
  end

  def thanks
    updated_by                    = update_last_change_field(params[:customer][:first_name].present? ? params[:customer][:first_name] : customer.first_name )
    params[:customer][:update_by] = updated_by
    customer                      = Customer.create(params[:customer])
    customer.notes.create({
      :note_text => params[:extra].collect { |label, value| "#{label.humanize.titleize}: #{value}" }.join(', ')
    })
    customer.properties.create(params[:property])
    Account.create({
      :parent_id    => customer.id,
      :parent_type  => 'Customer',
      :email        => customer.email,
      :password     => Account.generate_random_password,
      :role         => 'customer'
    })
    @page_title     = "Thank you!"
  end

  def quote
    @page_title     = "Get A Free Quote"
    @content_class  = "get-quote-page"
    @customer       ||= Customer.new
    @property       ||= @customer.properties.build
    render(layout: "getquote")
  end
  alias :getaquote :quote

  def billing
    id = cookies.signed[:incomplete_gaq_customer_id]
    return redirect_to :action =>'quote' if id.nil?

    @customer             = Customer.find(id)
    @customer_total_price = @customer.pay_amount.to_f * @customer.num_payments
    @property             = @customer.properties.last
    @copy_address         = true if params[:copy_billing_info]

    if !request.post?
      render(layout: "getquote")
      return
    end

    # customer pay_amount and num_payments update

    if params[:customer][:pay_amount] && params[:customer][:num_payments]
      if params[:customer][:num_payments].to_s == "12"
        @customer_pay_amount = (@customer.pay_amount.to_f / params[:customer][:num_payments].to_i).round(3)
      else
        @customer_pay_amount = params[:customer][:pay_amount]
      end
      @customer_num_payments = params[:customer][:num_payments].to_i
    end

    params[:billing_address][:address_type] = 'Billing'

    billing_attributes  = {
                            :billing_first_name => params[:customer][:billing_first_name],
                            :billing_last_name => params[:customer][:billing_last_name]
                          } if params[:customer]

    @customer.update_attributes(billing_attributes) if billing_attributes

    billing_address     = @customer.create_billing_address(params[:billing_address])
    state               = State.find_by_name(@customer.state)

    if state.present? && state.gateway_id.present?
      gateway       = state.gateway
      authorize     = {:login=> gateway.login_id.strip, :password=> gateway.transaction_key.strip }
    else
      gateway       = Gateway.default_gateway
      authorize     = gateway.present? ? {:login=> gateway.login_id.strip, :password=> gateway.transaction_key.strip } : nil
    end

    gateway = ActiveMerchant::Billing::AuthorizeNetCimGateway.new(authorize)
    options = {:profile => {:merchant_customer_id => @customer.id, :email => @customer.email }}

    # create customer profile
    customer_profile    = gateway.create_customer_profile(options)
    customer_profile_id = customer_profile.params["customer_profile_id"]
    credit_card         = ActiveMerchant::Billing::CreditCard.new(:number => params[:credit_card_number], :month => params[:date][:month], :year => params[:date][:year], :first_name =>  @customer.first_name, :last_name => @customer.last_name)
    payment_profile     = {:bill_to => {:first_name => @customer.billing_first_name, :last_name => @customer.billing_last_name, :address => billing_address.address,  :city => billing_address.city, :state => billing_address.state, :country => 'US', :zip => billing_address.zip_code}, :payment => { :credit_card => credit_card } }
    options             = {:customer_profile_id => customer_profile_id, :payment_profile => payment_profile }

    # create customer payment profile
    start_date                  = 1.week.from_now
    customer_payment_profile    = gateway.create_customer_payment_profile(options)
    customer_payment_profile_id = customer_payment_profile.params['customer_payment_profile_id']

    # end start ActiveMerchant Billing AuthorizeNetCimGateway
    #add_for_customer_credit_card(@customer)
    if customer_profile_id.present? && customer_payment_profile_id.present?
      gateway     = ActiveMerchant::Billing::AuthorizeNetGateway.new(authorize)
      start_date  = 1.week.from_now
      npayment    = @customer.num_payments == 0 ? 1 : @customer.num_payments
      options_payment = {
        :billing_address => {
            :first_name => @customer.billing_first_name,
            :last_name  => @customer.billing_last_name,
            :address1   => billing_address.address,
            :city       => billing_address.city,
            :state      => billing_address.state,
            :zip        => billing_address.zip_code,
            :country    => "US"
        },
        :subscription_name  => $installation.name,
        :interval           => { :unit => :months, :length => 12 / npayment },
        :duration           => { :start_date => start_date.strftime('%Y-%m-%d'), :occurrences => @customer.num_payments }
      }
      # create customer profile transaction
      response = gateway.recurring(@customer.pay_amount.to_f * 100.0, credit_card, options_payment)
    end
  
    if response.present? && response.success?
      @customer.update_attributes({
        :subscription_id              => response.params['subscription_id'],
        :credit_card_number           => params[:credit_card_number],
        :expirationDate               => "#{params[:date][:year]}-#{params[:date][:month]}",
        :customer_profile_id          => customer_profile_id,
        :customer_payment_profile_id  => customer_payment_profile_id
      })

      # for affiliate users, should add 2 months free: contract
      if cookies.signed[:is_affiliate_user]
         contract_length_months = (params[:contract_length].to_i * 12  + 2).months
      else # non affiliate user
         contract_length_months = (params[:contract_length].to_i * 12).months
      end

      @customer.renewals.create({
        :years      => params[:contract_length].to_i,
        :amount     => @customer.pay_amount.to_f,
        :starts_at  => start_date,
        :ends_at    => start_date + contract_length_months
      })
      password        = Digest::SHA1.hexdigest("#{rand(1<<64)}")[0...5]
      
      my_account                = Account.new
      my_account.parent_id      = @customer.id
      my_account.parent_type    = 'Customer'
      my_account.email          =  @customer.email  
      my_account.password       = password 
      my_account.role           = 'customer'
      my_account.last_login_ip  = request.remote_ip
      my_account.last_login_at  = Time.zone.now
      my_account.save
      
      flash[:result]  = :success

      cookies.delete :incomplete_gaq_customer_id
      Postoffice.template('New Web Order', $installation.admin_email, {:customer => @customer}).deliver
      Postoffice.template('New GAQ Order', 'gaqleads@selecthomewarranty.com', {:customer => @customer}).deliver
      @customer.update_attributes(:cc_by => "customer", :pay_amount => @customer_pay_amount, :num_payments => @customer_num_payments)
      add_for_customer_credit_card(@customer)
    else
      Rails.logger.info "Payment error: #{response.inspect}"
      flash[:result] = response
    end
    render :action => 'thankyou'
  end

  def please_call
    @page_title = "Please Call Us"
    @content    = Content.for(:please_call).html_safe
  end

  def affiliate # affiliate home page
    @myurl      = request.referrer.to_s.split("affiliate").first
    @subId      = params[:subids]
    @partner    = Partner.find_by_discount_code(params[:discountcode])
    @affiliate  = SubAffiliate.find_by_sub_ids(@subId)
    if @partner.present?
      render :layout => false
    else
      redirect_to root_path
    end
  end

  def restricted_state
    @page_title = "Restricted State"
    state       = session[:state].present? ? session[:state].upcase : ''
    @content    = "Sorry, we currently don't offer coverage in #{state} - please stay tuned!"
  end

  def submit_affiliate
  end

  def purchase
    referrer2 = request.referrer.to_s
    @subId    = params[:subid]
    if referrer2.to_s.scan("affiliate").present?
      @partner                  = Partner.find_by_discount_code(params[:discountcode])
      params[:customer][:subid] = @subId if @subId.present?
      @page_title               = "Purchase A Plan"
      @is_affiliate_user        = params[:affiliate] rescue false
      if params[:post_request_2].present? && params[:post_request_2].to_s == 'post_request_2'
        perform_payment_post("affiliate")
      else
        perform_payment_get("affiliate")
      end
    else
      @page_title         = "Purchase A Plan"
      @is_affiliate_user  = params[:affiliate] rescue false
      if params[:post_request_2].present? && params[:post_request_2].to_s == 'post_request_2'
        perform_payment_post("gaq")
      else
        perform_payment_get("gaq")
      end
    end
  end

  def perform_payment_get(temp)
    return redirect_to :action => 'quote' if params[:customer].nil?
    params[:extra] ||= {}
    mapped = {
      'Single Family' => 'single',
      '2 Family'      => 'duplex',
      '3 Family'      => 'triplex',
      '4 Family'      => 'fourplex',
      'Condominium'   => 'condo'
    }
    @partner = Partner.find_by_discount_code(params[:discountcode])
    params[:customer].merge!(:home_type => mapped[params[:type_of_home]])
    params[:customer][:partner_id]        = @partner.id if @partner.present?
    params[:customer][:customer_address]  = params[:property][:address]
    params[:customer][:customer_city]     = params[:property][:city]
    params[:customer][:customer_state]    = params[:property][:state]
    params[:customer][:customer_zip]      = params[:property][:zip_code]
    params[:customer][:customer_from]     = "customer"
    params[:customer][:status_id]         = 0
    params[:customer][:ip]                = request.remote_ip
    params[:customer][:pay_amount]        = 499.95  ## For Billing Info
    params[:customer][:partner_id]        = @partner.id if @partner.present?
    params[:customer][:subid]             = params[:subid]
    if params[:customer].present?
      updated_by                          = update_last_change_field(params[:customer][:first_name].present? ? params[:customer][:first_name] : '' )
      params[:customer][:update_by]       = updated_by
    end
    @customer                             = Customer.new(params[:customer])
    @customer.partner_id                  = @partner.id if @partner.present?
    if temp.to_s == "affiliate"
      active_states = State.active_affiliate.map(&:name) # $installation.active_states
    else
      active_states = State.active_gaq.map(&:name) # $installation.active_states
    end
    if @customer.save
      cookies.signed[:incomplete_gaq_customer_id] = { :value => @customer.id, :expires => 6.months.from_now }
      if @is_affiliate_user then
        cookies.signed[:is_affiliate_user] = { :value => true, :expires => 6.months.from_now }
      else
        cookies.signed[:is_affiliate_user] = { :value => false, :expires => 6.months.from_now }
      end
      # IP track
      #ip= IpTrack.new
      #ip.remote_ip      = request.env['HTTP_X_FORWARDED_FOR'] || request.remote_ip
      #ip.browser_title  = request.env['HTTP_USER_AGENT']
      #ip.source_format  = "GAQ2"
      #ip.customer       = @customer
      #ip.save
      @property         = @customer.properties.create(params[:property])
      unless active_states.include?(params[:property][:state].upcase)
        session[:state] = params[:property][:state]
        return redirect_to restricted_state_path
      else
        @customer.send_mail_about_new_price_quote(@customer)
        @note = params[:extra].collect { |label, value| "#{label.humanize.titleize}: #{value}" }.join(', ') if params[:extra]
        if @customer.home_size_code == 1
          return redirect_to please_call_path
        else
          render(layout: "getquote")
        end
      end
    else
      redirect_to "/purchase" ## replace :back to /purchase
    end
  end

  def perform_payment_post(type)
    params[:coverages] ||= {}
    params[:customer][:coverage_addon]    = (params[:coverages].collect { |k,v| k }).join(', ')
    params[:customer][:coverage_ends_at]  = 1.year.from_now
    Rails.logger.info("--- id = #{cookies.signed[:incomplete_gaq_customer_id]}")
    id = cookies.signed[:incomplete_gaq_customer_id]
    if id.nil?
      return redirect_to :action => @is_affiliate_user ? 'affiliate':'quote'
    else
      @customer = Customer.find(cookies.signed[:incomplete_gaq_customer_id])
      if @customer.status_id != 0
        return redirect_to please_call_path
      else
        @customer.update_attributes(params[:customer])
        @customer.notes.create({ :notes_text => @note }) if @note
        if params[:property_id].to_i == 0 then @customer.properties.create(params[:property]) end
        redirect_to :action => 'billing'
      end
    end
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

  def add_for_customer_credit_card(customer)
    @customer = customer
    number    = @customer.credit_card_number.blank? ? '1234123412340000' : @customer.credit_card_number
    date      = @customer.expirationDate || Date.today.strftime('%m/%d')
    card      = @customer.credit_cards.new({
                  :first_name => @customer.first_name,
                  :last_name  => @customer.last_name,
                  :phone      => @customer.customer_phone,
                  :exp_date   => date,
                  :last_4     => number[-4..-1]
                })
    card.number = number
    if card.save
        prexisting_address = @customer.billing_address || @customer.addresses.first
        billing_address    = prexisting_address ?
                              prexisting_address.duplicate_for_addressable!(card) :
                              Address.create({
                                :address => '123 Maple St', :city => 'Nowhere', :state => 'KS', :zip_code => '12345',
                                :addressable_type => 'CreditCard', :addressable_id => card.id
                              })
        card.update_attributes({ :address_id => billing_address.id })
    end
  end

  private

  def add_credit_card_to_customer customer_id
    @customer = Customer.find(customer_id) rescue nil
    if @customer.nil?
      return
    end
    puts "\n\nAdding credit card of customer...."
    number    = @customer.credit_card_number.blank? ? '1234123412340000' : @customer.credit_card_number
    date      = @customer.expirationDate || Date.today.strftime('%m/%d')
    card      = @customer.credit_cards.new({
      :first_name => @customer.first_name,
      :last_name  => @customer.last_name,
      :phone      => @customer.customer_phone,
      :exp_date   => date,
      :last_4     => number[-4..-1]
    })
    card.number = number

    if card.save
       prexisting_address = @customer.billing_address || @customer.addresses.first
       billing_address    = prexisting_address ?
                          prexisting_address.duplicate_for_addressable!(card) :
                          Address.create({
                            :address => '123 Maple St', :city => 'Nowhere', :state => 'KS', :zip_code => '12345',
                            :addressable_type => 'CreditCard', :addressable_id => card.id
                          })
      card.update_attributes({ :address_id => billing_address.id })
    else
      puts "\n\n\ncard save filed..................\n\n"
    end
  end

  protected

  def internal_page
    @content_class = "internal-page"
  end

end
