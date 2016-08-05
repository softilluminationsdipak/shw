class Admin::AgentsController < ApplicationController
  before_filter :check_login
  before_filter :redirect_to_customer_page
  before_filter :check_permissions

  #layout 'new_admin', :only => ['index', 'edit']
  layout 'admin_settings', :only => [:index, :edit]
  ssl_exceptions []
  
  def index
    add_breadcrumb "Agents"
    @selected_tab = 'agents'
    @page_title   = "Agents"
    if current_account.admin?
      @agents       = Agent.all
    else
      redirect_to '/admin/sales/dashboard'
    end
  end
  
  def edit ## For Sales
    add_breadcrumb "Agents","/admin/agents"
    add_breadcrumb "Edit"
    
    @selected_tab = 'agents'
    @agent        = Agent.find params[:id]
    @page_title   = "Agents - #{@agent.name}"
    
    # check permission to edit main field of Agent, just password, and role
    @is_readonly_main_field = false
    if (current_account.parent_type == "Agent") && (current_account.parent.admin ==1)
      @is_readonly_main_field = false
    end
    
    if params[:from] and params[:to]
      begin
        @from             = Date.strptime(params[:from],"%m/%d/%y")
        @to               = Date.strptime(params[:to],"%m/%d/%y")
        @all_transactions = Transaction.for_agent_renewal_between(@agent, @from, @to)
        @total            = @all_transactions.collect{ |t| t.amount if t.approved? }.delete_if { |e| e == nil }.sum
        @renewals         = Renewal.for_agent_renewal_between(@agent, @from, @to).group(:customer_id).order("ends_at ASC").paginate(:page => params[:page], :per_page  => 25)
      rescue  # from, and to date format is invalid
        @all_transactions = Transaction.for_agent(@agent)
        @total            = @all_transactions.collect{ |t| t.amount if t.approved? }.delete_if { |e| e == nil }.sum
        @renewals         = Renewal.for_agent(@agent).group(:customer_id).order("ends_at ASC").paginate(:page => params[:page], :per_page  => 25)
      end
    else
      @all_transactions = Transaction.for_agent(@agent)    
      @total            = @all_transactions.collect{ |t| t.amount if t.approved? }.delete_if { |e| e == nil }.sum
      @renewals         = Renewal.for_agent(@agent).group(:customer_id).order("ends_at ASC").paginate(:page => params[:page], :per_page  => 25)
    end  
  end
  
  def new
    @agent = Agent.new
    @agent.build_account unless @agent.account.present?
  end

  def create
    agent   = Agent.new(params[:agent])
    account = Account.new(params[:account])
    if account.valid?
      agent         = Agent.create(params[:agent])
      account       = Account.new(params[:account])
      account.role  = params[:account][:role]
      account.parent_id   = agent.id
      account.parent_type = 'Agent'
      account.save
      notify(Notification::CREATED, { :message => 'created', :subject => agent })
      @error_message = nil
    else
      @error_message = account.errors.full_messages
    end
    respond_to do |format|
      format.html{
        flash[:notice] = 'Successfully done!'
        redirect_to :action => 'index'
      }
      format.js{}
    end
  end
  
  def update
    agent   = Agent.find params[:id]
    updated = agent.update_attributes(params[:agent])
    updated = updated and agent.account.update_attributes(params[:account])
    notify(Notification::UPDATED, agent) if updated
    
    if params[:agent][:commission_percentage]
      flash[:notice] = 'Successfully done!'
      redirect_to "/admin/agents/edit/#{params[:id]}?from=#{params[:from]}&to=#{params[:to]}"
    else
      respond_to do |format|
        format.html{
          flash[:notice] = 'Successfully Updated!'
          redirect_to :action => 'index'
       }
      end
    end
  end
  
  def destroy
    agent = Agent.find params[:id]
    notify(Notification::DELETED, agent)
    agent.destroy
    redirect_to :action => 'index'
  end

end
