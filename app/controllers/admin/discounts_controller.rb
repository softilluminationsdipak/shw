class Admin::DiscountsController < ApplicationController
  before_filter :check_login, :except => [:async_validate]
  before_filter :redirect_to_customer_page
  before_filter :check_permissions
  
  layout 'admin_settings', :except => [:async_validate]
  protect_from_forgery :except => :async_validate

  ssl_exceptions []
  
  def index
    add_breadcrumb "Discounts"
    @selected_tab = 'content'
    @page_title = "Discounts"
    @discounts = Discount.find(:all)
  end
  
  def edit
    add_breadcrumb "Discounts", "/admin/discounts"
    add_breadcrumb "Edit"
    
    @selected_tab = 'content'
    @discount = Discount.find params[:id]
    @page_title = "Discounts - #{@discount.code}"
  end
  
  def create
    params[:discount][:value].gsub!(/(\$|\%)/, '').to_f
    if params[:is_percentage] then params[:discount][:value] = params[:discount][:value].to_f * 0.01 end

    begin
      discount = Discount.new(params[:discount])
      discount.is_monthly = params[:discount][:is_monthly]
      discount.value=params[:discount][:value]
      discount.name = params[:discount][:name]

      # input mm/dd/yy format, but starts_at and ends_at are DateTime format
      # so have to convert
      sa= Date.strptime(params[:discount][:starts_at],"%m/%d/%y")
      ea=Date.strptime(params[:discount][:ends_at],"%m/%d/%y")

      discount.starts_at = DateTime.new(sa.year,sa.month,sa.mday,0,0,0)
      discount.ends_at = DateTime.new(ea.year,ea.month,ea.mday,0,0,0)
      discount.save
    rescue  # invalid date time format

      return redirect_to :action => 'index'
    end

    notify(Notification::CREATED, discount)
    
    redirect_to :action => 'index'
  end
  
  def update
    params[:discount][:value].gsub!(/(\$|\%)/, '').to_f
    if params[:is_percentage] then params[:discount][:value] = params[:discount][:value].to_f * 0.01 end
    discount = Discount.find(params[:id])

    begin
      updated = discount.update_attributes(params[:discount])

      sa= Date.strptime(params[:discount][:starts_at],"%m/%d/%y")
      ea=Date.strptime(params[:discount][:ends_at],"%m/%d/%y")

      discount.starts_at = DateTime.new(sa.year,sa.month,sa.mday,0,0,0)
      discount.ends_at = DateTime.new(ea.year,ea.month,ea.mday,0,0,0)
      discount.save
    rescue
      return redirect_to :back
    end

    notify(Notification::UPDATED, discount) if updated
    
    redirect_to :action => 'index'
  end
  
  def destroy
    discount = Discount.find(params[:id])
    notify(Notification::DELETED, discount)
    discount.destroy
    redirect_to :action => 'index'
  end
  
  def async_validate
    Discount.find(:all).each do |discount|
      if params[:discount_code] == discount.code and discount.is_valid?
        if params[:id].present?
          customer = Customer.find(params[:id])
          customer.discount_id = discount.id 
          customer.save
        end
        render :json => { :validated => discount.value, :discount_id => discount.id }
        return
      end
    end
    
    render :json => { }
  end
end
