# TODO: Move all these keys to .env
API_KEY_ICONTACT_ACCOUNT = "" #"slK5VadopvE5zjc49rBpHaHJfgxlvBfN"
SHARED_SECRET_ICONTACT_ACCOUNT = "" #"NQJyQMM58h1yr4sqlTFSUds0kPbFggjT"
LOGIN_ICONTACT_ACCOUNT = "" #"morris@nationwidehomewarranty.com"
PASSWORD_ICONTACT_ACCOUNT = "" #"moandabe07"

Eripme::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  #config.action_view.debug_rjs             = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = true

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  config.action_mailer.delivery_method = :sendmail
  config.action_mailer.sendmail_settings = {:arguments => "-i"}

  config.action_mailer.perform_deliveries = true

  # Use :debug for SQL logging
  config.log_level = :info

  # assets mode setting
  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true
  config.action_dispatch.ip_spoofing_check = false
  
  SslRequirement.disable_ssl_check = true

  # for authorize.net test

  # TODO: Move all these keys to .env
  # social media integration
  ENV['FB_APP_KEY']     = '692633414102851'
  ENV['FB_SECRET_KEY']  = '6f96c4d8b6d10c4e31d546ca27ad01bc'
  ENV['TW_APP_KEY']     = 'svjZ17d1lIiMothdHbQzQ'
  ENV['TW_SECRET_KEY']  = 'LEPdOEHQMlRjIm0PVWASK0l94pfawlTa0XKTOG2NLQE'
  ENV['DOMAIN_CONFIG']  = 'selecthomewarranty.com'

  ActionMailer::Base.smtp_settings = {
    :address => "smtp.mandrillapp.com",
    :port => '587',
    :domain => "softilluminations.com",
    :authentication => 'plain',
    :user_name => "info@selecthomewarranty.com",
    :password => "INSURANCEselect321",
    :enable_starttls_auto => true
  }
  
end