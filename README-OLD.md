## Prerequisites

apt-get install ruby rubygems mysql-server libmysqlclient-dev libopenssl-ruby
apt-get install imagemagick libmagickcore-dev libmagickwand-dev

# And for fresh Ubuntu without C compiling capabilities:
apt-get install ruby1.8-dev make gcc libc6-dev build-essential

## Rails 3 version

gem install bundler
bundle install

## Rails2 version

# You may need older rubygems in some cases:
gem update --system 1.6.2

gem install rails -v=2.3.2
gem install mysql2 -v=0.2.6
gem install prawn
gem install chronic packet 
gem install crypt
gem install will_paginate -v=2.3.16
gem install rmagick
gem install system_timer

## Production with apache2

apt-get install apache2 libcurl4-openssl-dev libssl-dev apache2-prefork-dev libapr1-dev libaprutil1-dev
gem install passenger
passenger-install-apache2-module

NOTE: Don't forget to enable passenger as apache module (passenger installer will tell what exactly to add to apache config files)

## Initial data

rake db:schema:load
rake db:data:load MODEL=Package
rake db:data:load MODEL=Coverage
./script/rails runner 'Coverage.load_habtm_from_file'
rake db:data:load MODEL=EmailTemplate
rake db:data:load MODEL=Content

rake select:create_default_admin

