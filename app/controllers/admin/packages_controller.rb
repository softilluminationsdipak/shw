class Admin::PackagesController < ApplicationController
	before_filter :check_login
	before_filter :redirect_to_customer_page
	before_filter :check_permissions
	
	layout 'admin_settings'
	
  ssl_exceptions []

	def index
    add_breadcrumb "Packages"
    
		@selected_tab = "content"
		@page_title = "Packages"
		@packages = Package.all
		@optional_coverages = Coverage.all_optional
		@package_coverages  = Coverage.for_packages
		@package_coverage_sets = Coverage.for_packages.reverse / 4
	end
	
	def update
		params[:packages].each { |id, hash| Package.find(id).update_attributes(hash) }
		notify(Notification::UPDATED, { :subject_summary => 'Packages'})
		redirect_to :action => 'index'
	end
	
	def update_coverages
	  params[:coverages].each do |id, hash|
	    coverage = Coverage.find(id)
	    coverage.update_attributes(hash)
	    unless hash['price'].present?
	    	coverage.update_attributes(:price => 0.0)
	    end
	    coverage.destroy if hash['should_be_deleted'] == 'true'
	    coverage.destroy and notify(Notification::DELETED, coverage) if coverage.should_be_deleted == 'true'
	  end
	  notify(Notification::UPDATED, { :subject_summary => params[:which_coverages] })
	  redirect_to :action => 'index'
	end
	
	def create_coverage
		if params[:coverage].present? && params[:coverage][:coverage_name].present? && params[:coverage][:price].present?
	  	c = Coverage.create(params[:coverage]) 
	  	notify(Notification::CREATED, c)
	  end
	  redirect_to :action => 'index'
  end
end
