class Admin::CreditCardsController < ApplicationController
  before_filter :check_login
  before_filter :find_customer, :only => [:list_for_customer, :add_for_customer]
  before_filter :find_card, :only => [:destroy, :update, :bill]
  before_filter :check_permissions

  ssl_exceptions []
  
  def update
    last_4_digit_in_param= params[:card][:number][-4..-1] || '0000'
    new_number = params[:card][:number]
    new_number_check_format = new_number.gsub(/[\D]/,'')

    # first check, CC number is numerical format.
    if new_number == new_number_check_format then
      # number is encrypted attribute , and encryped by key of last_4
      # so update last_4 first without update number
      # and update number finally

      new_param=params[:card].merge({:last_4 => last_4_digit_in_param})
      new_param.delete(:number) # number deleted, because attr_encrypted attribute
      # update without number
      @card.update_attributes(new_param)

      # update number finally
      @card.number=new_number
      cvnumber = CreditCardValidator::Validator.valid?(params[:card][:number])
      logger.warn("====cvnumber===#{cvnumber}=====")
      @card.save unless cvnumber.nil?
    else # if CC number is non-numerical, then change attributes except number
      params[:card].delete(:number)
      @card.update_attributes(params[:card])
    end

    # change address
    begin
      @card.address.update_attributes(params[:address])
    rescue
      @card.address = Address.create(params[:address])
    end

    #@card.address.update_attributes(params[:address])
    respond_to do |format|
      format.json{render :json => @card}
      format.html{redirect_to "/admin/customers/nmi_payment/#{@card.customer.id}"}
      format.js{}
    end

# original source
=begin
    @card.update_attributes(params[:card])
    @card.address.update_attributes(params[:address])
    render :json => @card
=end
  end
=begin  
  def bill
    amount = params[:amount].to_f
    begin
      response = @card.charge_cents!(amount * 100.0) if amount > 0.0
    rescue
      response = nil
    end
    if response && response.success?

      note = Note.create({
        :customer_id => @card.customer_id,
        :note_text => "Billed $%.2f to card ending in #{@card.last_4}." % amount,
        :agent_name => current_account.parent.name,
        :author_id => current_account.parent.id
      })
      notify(Notification::CREATED, { :message => 'created', :subject => note })
    else
      reason = response ? ", but it failed because: #{response.fields[:response_reason_text]}." : '.'
      note = Note.create({
        :customer_id => @card.customer.id,
        :note_text => "Attempted to bill $%.2f to card ending in #{@card.last_4}#{reason}" % amount,
        :agent_name => current_account.parent.name,
        :author_id => current_account.parent.id
      })
      notify(Notification::CREATED, { :message => 'created', :subject => note })
    end
    render :json => response ? response.fields : nil
  end
=end
  def bill
    amount = params[:amount].to_f
    begin
      response = @card.charge_cents!(amount * 100.0) if amount > 0.0
    rescue
      response = nil
    end
    if response && response.success?

      note = Note.create({
        :customer_id => @card.customer_id,
        :note_text => "Billed $%.2f to card ending in #{@card.last_4}." % amount,
        :agent_name => current_account.parent.name,
        :author_id => current_account.parent.id
      })
      notify(Notification::CREATED, { :message => 'created', :subject => note })
    else
      reason = response ? ", but it failed because: #{response.params['response_reason_text']}." : '.'
      note = Note.create({
        :customer_id => @card.customer.id,
        :note_text => "Attempted to bill $%.2f to card ending in #{@card.last_4}#{reason}" % amount,
        :agent_name => current_account.parent.name,
        :author_id => current_account.parent.id
      })
      notify(Notification::CREATED, { :message => 'created', :subject => note })
    end
    render :json => response ? response.params : nil
  end  
  def destroy
    @card.destroy
    render :json => @card
  end
  
  def list_for_customer
    credit_cards = {}
    if (current_account.parent_type == "Agent") && (current_account.parent.admin ==1)
      credit_cards = @customer.credit_cards.collect{|card| card.as_json(nil,nil,true) }
    else
      credit_cards = @customer.credit_cards.collect{|card| card.as_json(nil,nil,false) }
    end
  
    render :json => credit_cards
  end
  
  def add_for_customer
    #number = @customer.credit_card_number.blank? ? '1234123412340000' : @customer.credit_card_number
    date = @customer.expirationDate || Date.today.strftime('%m/%d')
    card = @customer.credit_cards.new({
      :first_name => @customer.first_name,
      :last_name  => @customer.last_name,
      :phone => @customer.customer_phone
    #  :exp_date => date,
    #  :last_4 => number[-4..-1]
    })
    #card.number = number
    #card.number = nil

    if card.save
       prexisting_address = @customer.billing_address || @customer.addresses.first
       billing_address = prexisting_address ?
                        prexisting_address.duplicate_for_addressable!(card) :
                        Address.create({
                          :address => '123 Maple St', :city => 'Nowhere', :state => 'KS', :zip_code => '12345',
                          :addressable_type => 'CreditCard', :addressable_id => card.id
                        })
       card.update_attributes({ :address_id => billing_address.id })
       render :json => card
    else
       puts "\n\n\ncard save filed.......#{card.errors.full_messages}...........\n\n"
       render :status => 200, :nothing => true
    end
  end
  
  protected
  
  def find_customer
    @customer = Customer.find(params[:id])
  end
  
  def find_card
    @card = CreditCard.find(params[:id])
  end
end
