class SubAffilatesController < ApplicationController
  
  before_filter :authenticate_partner
	before_filter :find_affiliates, :only => [:edit, :update, :destroy]
  layout "bootstrap_layout"

  def index
  	@partner          = current_partner
  	@new_sub_affilate = SubAffiliate.new
  	@sub_affiliates   = @partner.sub_affiliates
  end

  def create
  	@partner       = current_partner
  	@sub_affiliate = @partner.sub_affiliates.build(params[:sub_affiliate])
  	@sub_affiliate.save if @sub_affiliate.valid?
    respond_to do |format|
      format.html{redirect_to "/"}
      format.js
    end      
  end

  def update
    @affiliate.update_attributes(params[:sub_affiliate])
    respond_to do |format|
      format.html{redirect_to "/", :notice => "Successfully updated!"}
      format.js
    end  	
  end

  def edit
  	@partner           = current_partner
  	@new_sub_affilate  = @affiliate
  end

  def destroy
    @affiliate.destroy if @affiliate.present?
    redirect_to sub_affilates_path, :notice => "Successfully destroyed!"
  end
  
  private

  def find_affiliates
  	@affiliate = SubAffiliate.find(params[:id])
  end

end
