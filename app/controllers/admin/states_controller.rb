class Admin::StatesController < ApplicationController
  before_filter :redirect_to_customer_page
  before_filter :check_login
  before_filter :check_permissions
  
  layout 'admin_settings'

  def index
  	@states = State.all
  	@state 	= State.new
  end

  def create
  	@state = State.new(params[:state])
  	if @state.valid?
  		@state.save
      notify(Notification::CREATED, @state)
  		redirect_to "/admin/states", :notice => "Successfully Done!"
  	else
  		redirect_to "/admin/states", :notice => @state.errors.full_messages.first
  	end
  end

  def edit
  	@state = State.find(params[:id])
  end

  def update
  	@state = State.find(params[:id])
  	if @state.update_attributes(params[:state])
      notify(Notification::UPDATED, @state)
  		redirect_to "/admin/states", :notice => "Successfully Updated"
  	else
  		render :action => "edit"
  	end
  end

  def destroy
  	@state = State.find(params[:id])
    if @state.present?
  	  @state.destroy 
      notify(Notification::DELETED, @state)
    end
  	redirect_to "/admin/states", :notice => "Successfully destroy"
  end

end
