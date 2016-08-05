require 'net/imap'

class FaxSource < ActiveRecord::Base
  has_many :faxes
  validates_presence_of :key, :address, :number, :name
  
  def edit_url; ''; end
  
  def notification_summary
    "#{self.name} (#{self.number})"
  end
  
  def as_json(a=nil,b=nil)
    {
      :id => self.id,
      :name => self.name,
      :number => self.number,
      :address => self.address,
      :key => self.key,
      :password => self.fake_password # invisible real password to browser
    }
  end
  
  def FaxSource.contractors
    FaxSource.find_by_key('contractors')
  end
  
  def FaxSource.customers
    FaxSource.find_by_key('customers')
  end
=begin
  def redownload_fax!(fax)
    File.open("#{Rails.root}/log/#{self.key}.log", 'a') do |log|
      start = Time.now.in_time_zone(EST)
      log.puts "=== Starting re-retrieval of fax ##{id} at #{start}"
      log.puts "\t= Connecting to imap.gmail.com:993..."
      imap = Net::IMAP.new('imap.gmail.com', 993, true)
      
      log.puts "\t= Logging in as #{self.address}..."
      imap.login(self.address, self.password)
      
      log.puts "\t= Selecting INBOX..."
      imap.select('INBOX')
      
      envelope = nil
      if fax.message_id
        envelope = TMail::Mail.parse(imap.fetch(fax.message_id, 'RFC822')[0].attr["RFC822"])
        log.puts "\t= Fetched message ##{fax.message_id} off the server"
      else
        log.puts "\t= Iterating through ON #{fax.received_at.strftime("%d-%b-%Y")}..."
        imap.search(['ON', fax.received_at.strftime("%d-%b-%Y")]).each do |message_id|
          message = imap.fetch(message_id, 'RFC822')[0].attr["RFC822"]
          envelope = TMail::Mail.parse(message)
          if envelope.date == fax.received_at
            log.puts "\t\t* Found match: #{fax.received_at} == #{envelope.date}. Updating fax..."
            fax.update_attributes({:message_id => message_id})
            break
          end #if
        end #imap.search
      end #if
      
      attachment = envelope.attachments.first
      path = "#{Rails.root}/faxes/#{fax.id}.pdf"
      File.open(path, 'w') { |pdf|
        bytes = pdf.write(attachment.read)
        log.puts "\t= Wrote #{bytes} bytes to #{path}"
      }
      fax.update_attributes({ :path => path })
      
      list = Magick::ImageList.new(path)
      list[0].resize_to_fit(800).write("#{Rails.root}/faxes/previews/#{fax.id}.png")
      log.puts "\t= Wrote preview to faxes/previews/#{fax.id}.png"
      list[0].resize_to_fit(64).write("#{Rails.root}/faxes/thumbnails/#{fax.id}.png")
      log.puts "\t= Wrote thumbnail to faxes/thumbnails/#{fax.id}.png"
      
      log.puts "\t= Logging Out..."
      imap.logout
      
      log.puts "\t= Disconnecting..."
      imap.disconnect unless imap.disconnected?
      
      finish = Time.now.in_time_zone(EST)
      #Notification.notify(Notification::INFO, :subject_summary => "#{num_retrieved} #{self.name} Fax(es)", :message => 'retrieved') 
      log.puts "=== Finished retrieval of new faxes at #{finish}"
      log.puts "=== Took #{finish-start} seconds"
      log.puts
    end #File.open
  end
=end
  def retrieve!
      start = Time.now.in_time_zone(EST)
      
      begin
        imap = Net::IMAP.new('imap.gmail.com', 993, true)
        imap.login(self.address, self.password)
        imap.select('INBOX')
      rescue
        # invalid credential
        puts "Invalid credential for email account."
        puts "********************************************************"
        return
      end

    File.open("#{Rails.root}/log/#{self.key}.log", 'a') do |log|  
      log.puts "=== Starting retrieval of new faxes at #{start}"
      log.puts "\t= Connecting to imap.gmail.com:993..."
      log.puts "\t= Logging in as #{self.address}..."
      log.puts "\t= Selecting INBOX..."

      log.puts "\t= Iterating through NOT FLAGGED..."
      num_retrieved = 0
      last_scanned_message_no = 0

      imap.search(['NOT', 'FLAGGED']).each do |message_id|
        log.puts "\t\t* Message ID is #{message_id}"
        if message_id < self.last_scanned_id then
           log.puts "skip #{message_id}"
           next
        end

        last_scanned_message_no = message_id

        message = imap.fetch(message_id, 'RFC822')[0].attr["RFC822"]
        
        # envelope = TMail::Mail.parse(message)
        envelope = Mail.read_from_string message
        fax = Fax.new({ :received_at => envelope.date, :source_id => self.id, :message_id => message_id })
        unless fax.deduce_sender_fax_number_using_envelope(envelope)
          log.puts "\t\t\tCould not deduce fax number in subject or body. This does not appear to be a valid fax. Skipping!"
          next
        end
        
        log.puts "\t\t\tThis fax is from #{fax.formatted_sender_fax_number}"
        log.puts "\t\t\tThis fax has #{envelope.attachments.length} attachments" if envelope.attachments
        next if envelope.attachments.nil? || envelope.attachments.length < 1
        
        fax.save
        attachment = envelope.attachments.first
        path = "#{Rails.root}/faxes/#{fax.id}.pdf"
        File.open(path, 'w') { |pdf|
          bytes = pdf.write(attachment.read.force_encoding("UTF-8"))
          log.puts "\t\t\tWrote #{bytes} bytes to #{path}"
        }
        fax.update_attributes({ :path => path })

        # randomize object id
        # [FIXME] add Base65.encode(random number)
        seed = Random.new(Time.now.strftime("%s").to_i+fax.id)
        random_number = seed.rand(100000000).to_s
        log.puts "Gettign Random number: #{random_number}"
        
        object_id="#{random_number}#{fax.id}"
        fax.object_id = object_id
        fax.save

        # upload pdf into google storage
        begin
          $cloud_connection_client.insert_image_into_bucket($cloud_connection_client.main_bucket,"fax_#{fax.object_id}.pdf",path,"application/pdf")
          # setting ACL
          $cloud_connection_client.insert_object_acl($cloud_connection_client.main_bucket,"fax_#{fax.object_id}.pdf")

        rescue # token expired or connection exception
          $cloud_connection_client.refetch_token
        end


        # [FIXME] test code
        # ------------------------------------------------------------
        #if File.exist?(path) then
        #  log.puts "Path: #{path}"
        #  log.puts "PDF file size : #{File.size?(path)}"
        #else
        #  log.puts "Path: #{path}"
        #  log.puts "File does not exist!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
        #end
        # ------------------------------------------------------------

        begin
          list = Magick::ImageList.new(path)
#          list = Magick::Image.read(path)

          if list[0] == nil
            log.puts "\t\t\t/!\\ This fax is corrupt --- /!\\"
            fax.write_corrupt!
          else          
            list[0].resize_to_fit(800).write("#{Rails.root}/faxes/previews/#{fax.id}.png")
            log.puts "\t\t\tWrote preview to faxes/previews/#{fax.id}.png"

            # time to upload preview into google storage
            begin
              $cloud_connection_client.insert_image_into_bucket($cloud_connection_client.preview_bucket,"fax_preview_#{fax.object_id}.png","#{Rails.root}/faxes/previews/#{fax.id}.png","image/png")
              # setting ACL
              $cloud_connection_client.insert_object_acl($cloud_connection_client.preview_bucket,"fax_preview_#{fax.object_id}.png")

            rescue # token expired or connection exception
              $cloud_connection_client.refetch_token
            end


            list[0].resize_to_fit(64).write("#{Rails.root}/faxes/thumbnails/#{fax.id}.png")
            log.puts "\t\t\tWrote thumbnail to faxes/thumbnails/#{fax.id}.png"

            # time to upload thumb into google storage
            begin
              $cloud_connection_client.insert_image_into_bucket($cloud_connection_client.thumb_bucket,"fax_thumb_#{fax.object_id}.png","#{Rails.root}/faxes/thumbnails/#{fax.id}.png","image/png")
              # setting ACL
              $cloud_connection_client.insert_object_acl($cloud_connection_client.thumb_bucket,"fax_thumb_#{fax.object_id}.png")

            rescue # token expired or connection exception
              $cloud_connection_client.refetch_token
            end

          end
        rescue Magick::ImageMagickError => e
          log.puts "Exception Message: #{e.message}\nBacktrace:"
          e.backtrace.each { |line| log.puts " >>" + line }

          log.puts "\t\t\t/!\\ This fax is corrupt /!\\"
          fax.write_corrupt!
        end
        num_retrieved += 1
        Notification.notify(Notification::CREATED, { :subject => fax, :message => 'retrieved' })
        
        #log.puts "\t\t\tLooking for other faxes from #{fax.formatted_sender_fax_number}..."
        #related_by_sender = Fax.related_by_sender(fax.sender_fax_number).first
        #log.puts "\t\t\t/!\\ Related sender checking has been disabled /!\\"
        #if related_by_sender
        #  fax.assignable = related_by_sender.assignable; fax.save
        #  log.puts "\t\t\tAssigned to #{fax.assignable_summary}"
        #  Notification.notify(Notification::UPDATED, { :message => "assigned to #{fax.assignable_summary}", :subject => fax })
        #else
        #  log.puts "\t\t\tNone found. Looking for Contractor with matching fax number..."
        #  contractor = Contractor.with_fax(fax.sender_fax_number).first
        #  if contractor
        #    fax.assignable = contractor; fax.save
        #    log.puts "\t\t\tAssigned to #{fax.assignable_summary}"
        #    Notification.notify(Notification::UPDATED, { :message => "assigned to #{fax.assignable_summary}", :subject => fax })
        #  else
        #    log.puts "\t\t\tNone found."
        #  end
        #end
#        unless RAILS_ENV == 'development'
          imap.store(message_id, "+FLAGS", [:Flagged])
          log.puts "\t\t\tMarked message #{message_id} as FLAGGED"
#        end
        # in development, fetch only one
        if Rails.env.development? or Rails.env.test?
          break
        end

      end
      if last_scanned_message_no > self.last_scanned_id then
         self.last_scanned_id = last_scanned_message_no
         self.save
         log.puts "end scanning in #{last_scanned_message_no}"
      end

      log.puts "\t= Logging Out..."
      imap.logout
      
      log.puts "\t= Disconnecting..."
      imap.disconnect unless imap.disconnected?
      
      finish = Time.now.in_time_zone(EST)
      Notification.notify(Notification::INFO, :subject_summary => "#{num_retrieved} #{self.name} Fax(es)", :message => 'retrieved') 
      log.puts "=== Finished retrieval of new faxes at #{finish}"
      log.puts "=== Took #{finish-start} seconds"
      log.puts
    end
  end
  
  def key_hash
    Digest::SHA1.hexdigest(self.key)[0...16]
  end
  
  def fake_password
    "******"
  end

  def password=(password)
    return nil if password.nil? or password.empty?
    # Crypt is deprecated library.
    #cipher = Crypt::Rijndael.new(self.key_hash)
    # Pad the password to meet the min block size of 16 bytes
    #self.password_hash = Base64.encode64(cipher.encrypt_string(password.ljust(16, ' ')))
    self.password_hash = Base64.encode64(password.ljust(16, ' '))
  end
  
  def password
    return '' if password_hash.nil?
    # Crypt is deprecated library.
    #cipher = Crypt::Rijndael.new(self.key_hash)
    # Strip whitespace because it may be padded to make 16 bytes
    #cipher.decrypt_string(Base64.decode64(self.password_hash)).strip
    Base64.decode64(self.password_hash).strip
  end

def self.init_default_fax_source
    if FaxSource.count == 0	# customers and contractors fax_source should be added default.
      fxs_customer=FaxSource.new
      fxs_customer.name = "customer source"
      fxs_customer.number = "00000"
      fxs_customer.address = "update@this.com"
      fxs_customer.key="customers"
      fxs_customer.password="change password"
      fxs_customer.save

      fxs_contractor=FaxSource.new
      fxs_contractor.name = "contractor source"
      fxs_contractor.number = "00000"
      fxs_contractor.address = "update@this.com"
      fxs_contractor.key="contractors"
      fxs_contractor.password="change password"
      fxs_contractor.save

      logger.info "Default fax source added."
    end
  end

end
