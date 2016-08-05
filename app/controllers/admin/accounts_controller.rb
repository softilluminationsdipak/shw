class Admin::AccountsController < ApplicationController
  before_filter :check_login
  before_filter :check_permissions

  ssl_exceptions []

  def async_reset_password
    klass   = params[:object_type].constantize
    object  = klass.send('find', params[:id])
    if object.account.nil?
      render :json => { :text => "#{object.name} does not have a web account." }
    else
      render :json => { :text => object.account.reset_password }
    end
  end

  # Expects id and object_type
  # object_type must respond to #name and #email
  def async_grant_web_account
    params[:email_template_name] ||= 'Welcome'
    klass = params[:object_type].present? ? params[:object_type].constantize : "Customer"
    begin
      object = klass.send('find', params[:id])
    rescue
      object = Customer.find(params[:id]) if klass.to_s == "Customer"
    end
    result = Account.grant_web_account(object)

    if result.length == 8
      Postoffice.template(params[:email_template_name], object.email, {
        :attachments => params[:attachments],
        :customer => object,
        :password => result,
        :contractor => object
      },current_account.email).deliver
      notify(Notification::INFO, { :message => 'granted web access', :subject => object })

      render :json => {
        :text => "#{object.name} has been granted a web account. Their password is \"#{result}\", and they have been emailed the \"#{params[:email_template_name]}\" email."
      }
    else
      render :json => { :text => result }
    end
  end
end
