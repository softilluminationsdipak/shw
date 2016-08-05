# Load the rails application
require File.expand_path('../application', __FILE__)
# Another rubygems compatibility fix
# See http://www.redmine.org/issues/7516
if Gem::VERSION >= "1.3.6"
  module Rails
    class GemDependency
      def requirement
        r = super
        (r == Gem::Requirement.default) ? nil : r
      end
    end
  end
end

ActiveSupport::Deprecation.silenced = true

# Initialize the rails application
Eripme::Application.initialize!

# This block must go after all initializers to use $installation reliably
#require 'tlsmail'
Eripme::Application.configure do
  #Net::SMTP.enable_tls(OpenSSL::SSL::VERIFY_NONE)
  #config.action_mailer.delivery_method = :smtp
  ActionMailer::Base.smtp_settings = $installation[:smtp]
  #config.action_mailer.smtp_settings = $installation[:smtp]

  # QUICKFIX: gmail STMP is rejected from stage, using sendmail
  if Rails.env.staging? or Rails.env.production? or Rails.env.development?
    ActionMailer::Base.delivery_method = :sendmail
    ActionMailer::Base.sendmail_settings = {:arguments => "-i"}
    #config.action_mailer.delivery_method = :sendmail
    #config.action_mailer.sendmail_settings = {:arguments => "-i"}
  end
=begin
  if Rails.env.development?
    Rails.logger = Le.new('9e29f5f1-9416-4320-80d2-056f24c65e2e', debug: true)
  else
    Rails.logger = Le.new('9e29f5f1-9416-4320-80d2-056f24c65e2e')
  end
=end
end

# init fax source
# if there is no fax_source, then it registers manually.
# TODO: this code should be moved to a separate rake task
unless Rails.env.test? || Rails.env.development?
  # FaxSource::init_default_fax_source ## comment by dipak
end

# running fax fetch background worker...
# FaxFetchWorker.perform_at(40.minutes) ## comment by dipak
#FaxFetchWorker.perform_async
