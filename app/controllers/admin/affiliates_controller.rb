require 'csv'
class Admin::AffiliatesController < ApplicationController
  before_filter :check_login
  before_filter :check_permissions
  before_filter :find_affiliates, :only => [:edit, :update, :destroy, :show]
	
  layout 'admin_settings'
  
  def create
    @sub_affilate = SubAffiliate.new(params[:sub_affiliate])
    @sub_affilate.save if @sub_affilate.valid?
    respond_to do |format|
      format.html{redirect_to "/admin/sub-affiliates/index"}
      format.js
    end      
  end

  def index
  	@sub_affilates   = SubAffiliate.all
    @params_id       = params[:id]
    if params[:id].present?
      sub_affilate_id = params[:id]
      @sub_affilate   = SubAffiliate.find(sub_affilate_id.to_i)
      if params['start_date'].present? && params['end_date'].present?
        @start_date     = Date.strptime(params['start_date'], '%m/%d/%Y')
        @end_date       = Date.strptime(params['end_date'], '%m/%d/%Y')
        @find_customer  = @sub_affilate.customers.where("DATE(created_at) >= ? and DATE(created_at) <= ?", @start_date.to_date, @end_date.to_date).order("created_at DESC")
        @customers      = @find_customer.paginate(:page => params[:sub_affiliate], :order => 'created_at DESC', :per_page => 30)
      else
        @find_customer  = @sub_affilate.customers.order("created_at DESC")
        @customers      = @find_customer.paginate(:page => params[:sub_affiliate], :per_page => 30)
      end      
    end
    @new_sub_affilate = SubAffiliate.new
    respond_to do |format|
      format.html
      format.csv { send_data @find_customer.to_csv({}, @start_date, @end_date), :filename => "AffiliateLeads-#{@sub_affilate.partner.company_name.gsub(/[^0-9A-Za-z]/, '')}-#{Time.now.to_date.strftime('%m%d%Y')}" + ".csv" }
      format.xls { send_data @find_customer.to_csv({col_sep: "\t"}, @start_date, @end_date), filename: "AffiliateLeads-#{@sub_affilate.partner.company_name.gsub(/[^0-9A-Za-z]/, '')}-#{Time.now.to_date.strftime('%m%d%Y')}.xls"}
    end
  end

  def show
  end

  def edit
  end

  def update
    @affiliate.update_attributes(params[:sub_affiliate])
    respond_to do |format|
      format.html{redirect_to "/admin/sub-affiliates/index", :notice => "Successfully updated!"}
      format.js
    end
  end

  def destroy
    @affiliate.destroy if @affiliate.present?
    redirect_to "/admin/sub-affiliates/index", :notice => "Successfully destroyed!"
  end

  private

  def find_affiliates
  	@affiliate = SubAffiliate.find(params[:id])
  end

end