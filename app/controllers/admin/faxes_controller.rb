require 'open-uri'

class Admin::FaxesController < ApplicationController
  before_filter :set_selected_tab
  before_filter :check_login
  before_filter :check_permissions
  layout 'new_admin'

  ssl_exceptions []
  
  def index
    if current_account.role == "customer"
      redirect_to "/admin/customers/claims"
    else    
      add_breadcrumb "Faxes"
      @page_title = 'Unassigned Faxes'
    end
  end
  
  def async_list
    faxes= params[:id] ? Fax.unassigned.order("created_at DESC").from_source_key(params[:id]).paginate(:page => params[:CIPaginatorPage], :per_page  => (params[:CIPaginatorItemsPerPage] || 1).to_i) : Fax.unassigned.order("created_at DESC").paginate(:page => params[:CIPaginatorPage], :per_page  => (params[:CIPaginatorItemsPerPage] || 1).to_i)
    count = faxes.count
    render :json => {
      :CIPaginatorPage => params[:CIPaginatorPage],
      :CIPaginatorItemCount => count,
      :CIPaginatorCollection => faxes
    }

  end
  
  def async_list_for_contractor
    faxes = Fax.for_contractor(params[:id]).paginate(:page => params[:CIPaginatorPage], :per_page  => (params[:CIPaginatorItemsPerPage] || 1).to_i)
    
    count = faxes.count

    render :json => {
      :CIPaginatorPage => params[:CIPaginatorPage],
      :CIPaginatorItemCount => count,
      :CIPaginatorCollection => faxes
    }
  end
  
  def async_list_for_customer
    faxes = Fax.for_customer(params[:id]).paginate(:page => params[:CIPaginatorPage], :per_page  => (params[:CIPaginatorItemsPerPage] || 1).to_i)
    
    count = faxes.count

    render :json => {
      :CIPaginatorPage => params[:CIPaginatorPage],
      :CIPaginatorItemCount => count,
      :CIPaginatorCollection => faxes
    }
  end
  
  def thumbnail
      begin
        fax=Fax.find(params[:id])
        url = "http://commondatastorage.googleapis.com/#{$cloud_connection_client.thumb_bucket}%2Ffax_thumb_#{fax.object_id}.png"
        data = open(url).read
        send_data(data, :filename => "fax_#{params[:id]}_thumbnail.png", :type => 'image/png', :disposition => 'inline')
      rescue
        render :nothing => true
      end        
=begin
    begin
      thumb_file_path="#{Rails.root}/faxes/thumbnails/#{params[:id]}.png"
      File.open(thumb_file_path,'rb') do |f|
        send_data(f.read, :filename => "fax_#{params[:id]}_thumbnail.png", :type => 'image/png', :disposition => 'inline')
      end
    rescue ActionController::MissingFile
      fax = Fax.find(params[:id])
      fax.write_pngs!
      retry
    end
=end
  end
  
  def preview
      fax=Fax.find(params[:id])
      # test image url
      # url = "http://static8.depositphotos.com/1009979/841/v/450/dep_8413516-Painter-drawing-and-painting-icons.jpg"
      begin
        url = "http://commondatastorage.googleapis.com/#{$cloud_connection_client.preview_bucket}%2Ffax_preview_#{fax.object_id}.png"
        data = open(url).read
        send_data(data, :filename => "fax_#{params[:id]}_thumbnail.png", :type => 'image/png', :disposition => 'inline')
      rescue
        flash[:error]  =  "The source file for this fax is either corrupt or unavailable, please ask the customer to resubmit it"     
        redirect_to "/admin/faxes"        
      end
=begin
    begin
      send_file("#{Rails.root}/faxes/previews/#{params[:id].to_i}.png", :filename => "fax_#{params[:id]}_thumbnail.png", :type => 'image/png', :disposition => 'inline')
    rescue ActionController::MissingFile
      fax = Fax.find(params[:id])
      fax.write_pngs!
      retry
    end
=end
  end
  
  def download
    begin
      @fax=Fax.find(params[:id])
      fax=Fax.find(params[:id])
      url = "http://commondatastorage.googleapis.com/#{$cloud_connection_client.main_bucket}%2Ffax_#{fax.object_id}.pdf"
      data = open(url).read
      send_data(data, :filename => "fax_#{params[:id]}.pdf", :type => 'application/pdf', :disposition => 'inline')
    rescue
      flash[:error]  =  "The source file for this fax is either corrupt or unavailable, please ask the customer to resubmit it"     
      redirect_to "/admin/faxes"
    end
=begin
    send_file("#{Rails.root}/faxes/#{params[:id].to_i}.pdf", :type => 'application/pdf', :filename => "fax_#{params[:id]}.pdf")
=end
  end
  
  def async_assignment_search
    render(:json => []) and return if not params[:q] or params[:q].strip.empty?
    
    stripped_q = params[:q].gsub(/[^0-9]/, '')
    # See if it looks like a fax number
    is_fax_number = (params[:q][0..0] == '#') || params[:q].include?('-') || params[:q].include?('(') || params[:q].include?('.')
    # See if it's a valid fax number
    is_fax_number = is_fax_number && (stripped_q.to_i > 0) && (stripped_q.length == 10)
    # Turn it into a fax number
    params[:q] = stripped_q if is_fax_number
    is_string = params[:q].to_i == 0
    collection = []
    
    if is_fax_number and not is_string # Search Contractor Fax Numbers
      collection = Contractor.with_fax(params[:q])
    elsif not is_string # Search Customer IDs
      id_value=params[:q]
      # there could be prefix number , just '1', so if failed, then ignore '1' at first.
      begin
        collection = Customer.find(id_value.to_i)
      rescue
        collection = Customer.find(id_value[1,id_value.length].to_i)
      end
    elsif is_string # Search Customer names and Contractor companies
      remove_header = params[:q].gsub(/^#*(shw1)/i,'')

      if remove_header.to_i >0 then
        collection = Customer.find(remove_header.to_i) rescue nil
      else
        collection = Customer.with_name_like(params[:q])
        collection |= Contractor.with_company_like(params[:q])
      end
    end
    collection_array=collection.to_a rescue [collection]

    render :json => collection_array.collect { |i|
      {
        :id => i.id,
        :ruby_type => i.class.to_s,
        :id_fax => i.class == Contractor ? i.fax : i.contract_number,
        :name_company => i.class == Contractor ? i.company : i.name
      }
    }
  rescue ActiveRecord::RecordNotFound
    render :json => []
  end
  
  def async_assign
    fax = Fax.find(params[:id])
    assignable = params[:assignable_type].capitalize.constantize.find(params[:assignable_id])
    fax_assignable_join = FaxAssignableJoin.new
    #FaxAssignableJoin.create({
    #  :fax_id => fax.id,
    #  :assignable_id => assignable.id,
    #  :assignable_type => params[:assignable_type]
      fax_assignable_join.fax_id = fax.id
      fax_assignable_join.assignable_id = assignable.id,
      fax_assignable_join.assignable_type = params[:assignable_type]    
      fax_assignable_join.save
    #})
    notify(Notification::UPDATED, { :message => "assigned to #{assignable.notification_summary}", :subject => fax })
    render :json => fax
  end
  
  def async_unassign
    fax = Fax.find(params[:id])
    FaxAssignableJoin.find_by_fax_id_and_assignable_id_and_assignable_type(params[:id], params[:assignable_id], params[:assignable_type]).destroy
    notify(Notification::UPDATED, { :message => "unassigned", :subject => fax })
    render :json => fax
  end
  
  def destroy
    fax = Fax.find(params[:id])
    fax.destroy
    notify(Notification::DELETED, fax)
    render :json => fax
  end
  
  protected
  
  def set_selected_tab
    @selected_tab = 'dashboard'
  end
end
