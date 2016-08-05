#require 'rubygems'
require 'google/api_client'
require 'yaml'
require 'base64'


# google storage connection example
=begin
    @gstore=GoogleStorage.new
    @gstore.list_all_bucket

    @gstore.insert_image_into_bucket('faxhome','testu.png',"#{Rails.root}/faxes/uploadtest.png","image/png")
    @gstore.insert_image_into_bucket('faxhome','testu.pdf',"#{Rails.root}/faxes/uploadtest.pdf","application/pdf")
=end



class GoogleStorage

  # instance variable
  # ----------------------------------------------------
  # @client
  # @project_id
  # @storage

  def initialize

    # Setup authorization
    oauth_yaml = YAML.load_file("#{Rails.root}/config/google_storage.yml")
    #@client = Google::APIClient.new
    @client = Google::APIClient.new(
      :application_name => 'SHW',
      :application_version => '1.0.0'
    )

    key = Google::APIClient::PKCS12.load_key("#{Rails.root}/config/private_key.p12",oauth_yaml["private_key"])

    service_account = Google::APIClient::JWTAsserter.new(oauth_yaml["client_email"] ,oauth_yaml["scope"] ,key)
    @client.authorization = service_account.authorize

    # bucket name configuration
    @fax_bucket = oauth_yaml["fax_bucket"]
    @fax_thumb_bucket = oauth_yaml["fax_thumb_bucket"]
    @fax_preview_bucket = oauth_yaml["fax_preview_bucket"]

    @browser_access_key = oauth_yaml["simple_access_key"]

    # get project id
    @project_id = oauth_yaml["project_id"]

    # get token
    if @client.authorization.refresh_token && @client.authorization.expired?
      @client.authorization.fetch_access_token!
    end

    # Create client 
    # This can also be v1beta2, with a few small changes to the code.
    # Currently, the only differences are:
    # 1. "project_id" -> "project"
    # 2. For buckets.insert, "project" goes in "parameters", not "body_object"
    @storage = @client.discovered_api('storage', 'v1beta1')

  end

  def main_bucket
    @fax_bucket
  end

  def thumb_bucket
    @fax_thumb_bucket
  end

  def preview_bucket
    @fax_preview_bucket
  end

  def access_key
    @browser_access_key
  end

  def refetch_token
    if @client.authorization.refresh_token && @client.authorization.expired?
      @client.authorization.fetch_access_token!
    end
  end

  def get_location_and_token(bucket_name, object_name)
    # Get a specific object from a bucket
    bucket_get_result = @client.execute(
      api_method: @storage.objects.get,
      parameters: {bucket: bucket_name, object: object_name}
    )

    url = bucket_get_result.response.env[:response_headers]['location']
    token = "Bearer #{bucket_get_result.request.authorization.access_token}"

    return {:url => url, :token => token}
  end

  # ------------------------------------------------------
  # bucket related method

  def list_all_bucket
    # List all buckets in the project
    bucket_list_result = @client.execute(
      api_method: @storage.buckets.list,
      parameters: {"projectId" => @project_id}
    )
    puts "List of buckets: "
    puts bucket_list_result.data.inspect
    puts bucket_list_result.data.items.map(&:id)
    puts "...........\n"
  end

  def create_bucket(bucket_name)
    # Create a bucket in the project
    bucket_insert_result = @client.execute(
      api_method: @storage.buckets.insert,
      body_object: {id: bucket_name, project_id: @project_id}
    )
    p bucket_insert_result.data
    contents = bucket_insert_result.data
    puts "Created bucket #{contents.id} at #{contents.self_link}\n"
  end

  def delete_bucket(bucket_name)
    # Delete a bucket in the project
    bucket_delete_result = @client.execute(
      api_method: @storage.buckets.delete,
      parameters: {bucket: bucket_name}
    )
    puts "Deleting #{bucket_name}: #{bucket_delete_result.body}\n"
  end

  # --------------------------------------------------------
  # object related ....
  def list_all_in_bucket(bucket_name)
    # List all objects in a bucket
    objects_list_result = @client.execute(
      api_method: @storage.objects.list,
      parameters: {bucket: bucket_name}
    )
    puts "List of objects in #{bucket_name}: "
    objects_list_result.data.items.each { |item| puts item.name }
    puts "\n"
  end

  def get_object_from_bucket(bucket_name, object_name)
    # Get a specific object from a bucket
    bucket_get_result = @client.execute(
      api_method: @storage.objects.get,
      parameters: {bucket: bucket_name, object: object_name}
    )

    return bucket_get_result
  end

  def delete_object_in_bucket(bucket_name, object_name)
    # Delete object from bucket
    object_delete_result = @client.execute(
      api_method: @storage.objects.delete,
      parameters: {bucket: bucket_name, object: object_name}
    )
    if object_delete_result.response.status == 204
      puts "Successfully deleted #{object_name}.\n"
    else
      puts "Failed to delete #{object_name}.\n"
    end
  end

  def insert_image_into_bucket(bucket_name,object_name, image_path,mime_type)
    # Insert a small object into a bucket using metadata
    # object_content : contnet to be inserted

    image_media = Google::APIClient::UploadIO.new(image_path, mime_type)


    metadata_insert_result = @client.execute(
      api_method: @storage.objects.insert,
      parameters: {
        uploadType: 'resumable', 
        bucket: bucket_name, 
        name: object_name
      },
      media: image_media,
      body_object: { contentType: mime_type }
    )

    upload = metadata_insert_result.resumable_upload

    if upload.resumable?
      @client.execute(upload) # continue sending
    end

  end

  def insert_pdf_into_bucket(bucket_name,object_name, object_content)
    # Insert a small object into a bucket using metadata
    # object_content : contnet to be inserted

    metadata_insert_result = @client.execute(
      api_method: @storage.objects.insert,
      parameters: {
        uploadType: 'media', 
        bucket: bucket_name, 
        name: object_name
      },
      body_object: object_content
    )
    contents = metadata_insert_result.data
    puts "Metadata insert: #{contents.name} at #{contents.self_link}\n"
  end

  def insert_object_into_bucket(bucket_name,object_name, object_content)
    # Insert a small object into a bucket using metadata
    # object_content : contnet to be inserted

    metadata_insert_result = @client.execute(
      api_method: @storage.objects.insert,
      parameters: {
        uploadType: 'media', 
        bucket: bucket_name, 
        name: object_name
      },
      body_object: {
        contentType: 'text/plain', 
        data: Base64.encode64(object_content)
      }
    )
    contents = metadata_insert_result.data
    puts "Metadata insert: #{contents.name} at #{contents.self_link}\n"
  end

  def multipart_file_upload(bucket_name,object_name,filepath,mime_type)
    # There are three "normal" (i.e., not metadata) upload types.
    # "multipart" and "resumable" appear below, but at the time
    # of writing, the "media" option is not available in the 
    # Ruby API client.

    # Multipart upload
    media = Google::APIClient::UploadIO.new(filepath, mime_type)
    multipart_insert_result = @client.execute(
      api_method: @storage.objects.insert,
      parameters: {
        uploadType: 'multipart', 
        bucket: bucket_name, 
        name: object_name
      },
      body_object: {contentType: mime_type},
      media: media
    )
    contents = multipart_insert_result.data

    File.open("#{Rails.root}/log/google_image_add.log", 'a') do |log|  
      log.puts contents.inspect
      log.puts "......................"
      log.puts "name: #{contents.name}"
      log.puts "***************************"
      log.puts "self_link: #{contents.self_link}"
      log.puts "----------------------------"
    end


  end



  def get_object_acl(bucket_name, object_name)
    # Get object acl
    object_acl_get_result = @client.execute(
      api_method: @storage.object_access_controls.get,
      parameters: {bucket: bucket_name, object: object_name, entity: 'allUsers'}
    )
    puts "Get object ACL: "
    acl = object_acl_get_result.data
    puts "Users #{acl.entity} can access #{object_name} as #{acl.role}\n"
  end

  def insert_object_acl(bucket_name, object_name)
    # Insert object acl
    object_acl_insert_result = @client.execute(
      api_method: @storage.object_access_controls.insert,
      parameters: {bucket: bucket_name, object: object_name},
      body_object: {entity: 'allUsers', role: 'READER'}
    )
    puts "Inserting object ACL: #{object_acl_insert_result.body}\n"
  end


end
