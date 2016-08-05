class Partner::FacebookController < ApplicationController

	before_filter :authenticate_partner, :only => [:destroy]

	def create
    partner = Partner.from_omniauth(env["omniauth.auth"])
    session[:partner_id] = partner.id
    redirect_to affiliates_path
  end

  def destroy
    session[:partner_id] = nil
    redirect_to root_url
  end
end