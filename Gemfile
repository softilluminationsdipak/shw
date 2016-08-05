# Edit this Gemfile to bundle your application's dependencies.
# This preamble is the current preamble for Rails 3 apps; edit as needed.
source 'http://rubygems.org'

# For Server
gem 'rails', '3.2.17'
gem 'mysql2', '0.3.18'
gem 'bartt-ssl_requirement', '~>1.4.0', :require => 'ssl_requirement'
gem 'mail'
gem 'redis'
gem 'unicorn'
gem 'rails_12factor'
gem 'test-unit'
# Background Data Processing
gem 'attr_encrypted'
gem 'sidekiq'
gem 'dictionary'
gem 'backgroundrb-rails3', :require => 'backgroundrb'
gem 'sinatra', require: false
gem 'slim'
gem 'therubyracer', platforms: :ruby

# Authentication Support
gem 'cancan'
gem 'devise', '2.2.8'
gem 'omniauth-facebook'
gem 'omniauth-twitter'

# API Supp`ort
gem 'rabl'
gem 'paranoia', '~> 1.0'

# GUI Support
gem 'will_paginate', '~> 3.0'
gem 'prototype-rails'
gem 'tinymce-rails'
gem 'haml'
gem 'jquery-rails'
gem "breadcrumbs_on_rails"
gem 'rmagick', :require => 'RMagick'
gem "recaptcha", :require => "recaptcha/rails"
gem "font-awesome-rails"

# PDF Generation
gem 'prawn', '~> 1.0.0'
gem 'wicked_pdf'
gem 'pdfkit', '0.8.0'

# For Payments
gem 'authorize-net'
gem 'activemerchant', '1.58.0'
gem 'authorizenet'

# Error tracking & Analytics
gem 'rollbar'
gem 'newrelic_rpm'
gem "chartkick"
gem 'airbrake'

# Deployment Config
gem 'ey_config'
gem 'shelly-dependencies'
  
# google storage related
gem 'google-api-client'
gem 'launchy'
gem 'highline'

# Geolocation Support
gem 'geokit-rails'
gem "geo_location"

gem 'dotenv-rails'
gem 'jquery-minicolors-rails'
gem 'exception_notification'
gem 'zeroclipboard-rails'
gem 'wkhtmltopdf-binary'


group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
end

group :production do
	gem 'sinatra-logentries'
	gem 'le', '2.2.2'
end

group :development do
  gem 'thin'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'engineyard'
  #gem 'ninefold'
  #gem 'rails-erd', git: 'https://github.com/paulwittmann/rails-erd', branch: 'mavericks'
  #gem 'erd'
end

group :development, :test do
  gem 'brakeman', require: false
  gem 'rubocop'
end

group :test do
  gem 'capybara'
  gem 'database_cleaner'
  gem 'factory_girl_rails'
  gem 'factory_girl'
  gem 'rspec-rails'
  gem 'shoulda'
  # gem 'codeclimate-test-reporter'
  # gem 'simplecov', :require => false, :group => :test
end

gem "paperclip"

## Amazone S3
gem 'aws-s3', :require => 'aws/s3'
gem 'aws-sdk'

#gem 'wkhtmltopdf'
gem 'axlsx_rails'
gem 'curb'
gem 'addressable'
gem 'credit_card_validator'
gem 'librato-metrics'
gem 'mac-address'
gem 'geocoder'


gem 'capistrano-rails', group: :development
gem 'capistrano'
gem 'capistrano-bundler'
gem 'capistrano-rvm'
