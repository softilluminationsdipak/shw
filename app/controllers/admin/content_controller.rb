class Admin::ContentController < ApplicationController
  before_filter :check_login, :except => [:async_get_package_prices]
  before_filter :redirect_to_customer_page
  before_filter :check_permissions

  protect_from_forgery :except => [:async_load, :async_save, :async_get_package_prices]

  ssl_exceptions []
  
  def async_load
    render :json => Content.find_by_slug(params[:id])
  end
  
  def async_save
    #render :json => Content.find_by_slug(params[:id]).update_attributes({ :html => params[:html] })
    is_tos = (params[:is_tos].present? && params[:is_tos].to_s == "true") ? true : false
    Content.find_by_slug(params[:id]).update_attributes({ :html => params[:html], :is_tos => is_tos })
    render :nothing => true
  end
  
  def async_list
    render :json => Content.all.collect { |c|
      { :slug => c.slug, :label => c.slug.humanize }
    }
  end
  
  def async_create
    #render :json => Content.create(params[:content])
    content = Content.create(params[:content])
    notify(Notification::CREATED, content)
    @contents = Content.all
    respond_to do |format|
      format.html{redirect_to "/admin/content", :notice => "Successfully created!"}
      format.js{}
    end
  end
  
  def reload_content
    @content = Content.find_by_slug(params[:id])
    logger.warn("====#{@content.inspect}====")
    respond_to do |format|
      format.js
    end
  end

  def index
    add_breadcrumb "Contents"
    @contents = Content.where("slug != ?", "")
    @selected_tab = 'content'
    @page_title = 'Content'
    render :layout => 'admin_settings'
  end
  
  def async_get_package_prices
    hash = {}
    begin
      if params[:home_type]
        Package.find(:all).each { |package| hash[package.id] = package.send("#{params[:home_type].strip}_price") }
      end
    rescue
      hash={}
    end
    render :json => hash
  end

  def edit
    @content = Content.find(params[:id])
    render :layout => 'admin_settings'
  end

  def update
    content = Content.find(params[:id])
    if content.update_attributes(params[:content])
      notify(Notification::UPDATED, content)
      redirect_to "/admin/content", :notice => "Successfully Updated"
    else
      render :action => "edit", :notice => content.errors.full_messages.first
    end
  end

  def restore
    content = Content.find(params[:id])
    content.update_attributes(:is_delete => false) if content.present?
    redirect_to "/admin/content", :notice => "Successfully Restore!"
  end

  def destroy
    content = Content.find(params[:id])
    if content.present?
      content.update_attributes(:is_delete => true)
      notify(Notification::DELETED, content)
    end
    redirect_to "/admin/content", :notice => "Successfully Delete!"
  end

end
