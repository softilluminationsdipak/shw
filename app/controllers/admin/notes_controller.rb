class Admin::NotesController < ApplicationController
  before_filter :check_login
  #before_filter :only_admin_access, except: [:async_get_for_customer, :async_create, :async_update]
  before_filter :check_permissions
  ssl_exceptions []
  
  def async_get_for_customer
    render :json => Customer.find(params[:id]).notes
  end
  
  def async_create
    if params[:note]["note_text"].split(" ").size.to_i == 1
      params[:note]["note_text"] = params[:note]["note_text"].scan(/.{1,100}/m).join(" ")
    end
    params[:note][:agent_name] = @current_account.parent.name
    if params[:note][:notable_type] == "claim" && params[:note][:notable_id].present?
      claim = Claim.find(params[:note][:notable_id])
      claim.notes.build(:agent_name => @current_account.parent.name, :note_text => params[:note]["note_text"], :customer_id => params[:note]["customer_id"])
      claim.save
      notify(Notification::CREATED, { :message => 'created', :subject => claim })
    elsif params[:note][:notable_type] == "customer_service" && params[:note][:notable_id].present? 
      customer = Customer.find(params[:note][:notable_id])
      customer.notes.build(:agent_name => @current_account.parent.name, :note_text => params[:note]["note_text"], :customer_id => params[:note]["customer_id"])
      customer.save
      notify(Notification::CREATED, { :message => 'created', :subject => customer })
    elsif params[:note][:notable_type] == "billing" && params[:note][:notable_id].present? 
    else
      note = Note.new
      note.agent_name   = @current_account.parent.name
      note.note_text    = params[:note]["note_text"]
      note.customer_id  = params[:note]["customer_id"]
      note.save
      notify(Notification::CREATED, { :message => 'created', :subject => note })
    end        
    render :json => note
  end
  
  def async_update
    note = Note.find(params[:id])
    if params[:note][:note_text].split(" ").size.to_i == 1
      params[:note][:note_text] = params[:note][:note_text].scan(/.{1,100}/m).join(" ")
    end
    note.note_text = params[:note][:note_text]
    updated = note.save
    notify(Notification::CHANGED, { :message => 'updated', :subject => note }) if updated
    render :json => note
  end
  
  def create
    note = Note.create(params[:note])
    notify(Notification::CREATED, { :message => 'created', :subject => note })
    redirect_to admin_customer_edit_note_path(note.customer_id) # "/admin/customers/edit/#{note.customer_id}#notes"
  end

  #-----------------------------------------
  def add
    @contractorID = session[:account_id]
    @repair = Repair.find(:all,:conditions => ['contractor_id = ?', @contractorID])
    render :layout => 'admin.html.erb'	
  end
  #-----------------------------------------
  def add_note		
    if request.post?
      note = Note.create(params[:note])
      redirect_to "/admin/notes/add"
    else
      @note = Note.new
      render :layout => 'admin.html.erb'
    end
  end
 #-----------------------------------------
  def view_note
    @contractorID = session[:account_id]
    @note =  Note.find(:all,:conditions => ['repair_id = ?',params[:id]]) 
    render :layout => 'admin.html.erb'
  end
  #-----------------------------------------
  def rating
    render :layout => 'admin.html.erb'
  end 
  #-------------------------------------------
  def download_note_attachment
    @note = Note.find(params[:note_id])
    @attachment = @note.attachments.last
    #url = "http://commondatastorage.googleapis.com/contractor_insured%2F#{@attachment.attach_url}"
    #data = open(url).read
    #send_data(data, :filename => "#{@attachment.attach_url}", :type => 'application/pdf', :disposition => 'inline')
    data = open(@attachment.avatar.url.split("?").first).read
    send_data(data, :filename => "#{@attachment.avatar_file_name}", :type => "#{@attachment.avatar_content_type}", :disposition => 'attachment')
  end
  #---------------------------------------------
  def update
    @note = Note.find(params[:id])
    @claim = @note.notable
    if params[:note].present?
      @note.update_attributes(:note_text => params[:note][:note_text].scan(/.{1,100}/m).join(" "))
    end
    respond_to do |format|
      format.js
    end
  end

  def destroy
    @note = Note.find(params[:id])
    @note.destroy if @note
    redirect_to "/admin/claims/edit/#{@note.notable_id}", :notice => "Successfully destroyed!"
  end

  def update_note_reference
    @customer = Customer.find(params[:customer_id])
    @type = params[:type]
    respond_to do |format|
      format.js
    end
  end
end
