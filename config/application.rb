require File.expand_path('../boot', __FILE__)

require 'rails/all'
require 'net/http'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module Eripme
  class Application < Rails::Application
    config.secret_token = '6f22fa632e18b338b4babfa5fca632f5454fc97317cb52f372fa0f0fdd7f4d5bd95a060ff412c7230627b5c17906c9762c09208624bc1ab97f8d5344d8d4f467'
    config.filter_parameters << :password
    config.middleware.use "PDFKit::Middleware"

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"
    #config.force_ssl = true
    config.assets.enabled = true
    # config/application.rb
    config.assets.precompile << Proc.new do |path|
      if path =~ /\.(css|js)\z/
        full_path = Rails.application.assets.resolve(path).to_path
        app_assets_path = Rails.root.join('app', 'assets').to_path
        if full_path.starts_with? app_assets_path
          puts "including asset: " + full_path
          true
        else
          puts "excluding asset: " + full_path
          false
        end
      else
        false
      end
    end

    config.autoload_paths += %W(#{config.root}/lib)
    # config.autoload_paths += %W(#{config.root}/lib/middleware)
    config.active_record.whitelist_attributes = false

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password, :credit_card_number]
    config.middleware.use "PDFKit::Middleware", :print_media_type => true
  end

end

EST = ActiveSupport::TimeZone['Eastern Time (US & Canada)']

require 'safe'
require 'timeout'
