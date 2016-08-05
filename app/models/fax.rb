class Fax < ActiveRecord::Base
  belongs_to :source, :class_name => 'FaxSource'
  has_many :fax_assignable_joins, :dependent => :destroy
  
  validates_presence_of :source_id
  validates_numericality_of :source_id
  
  scope :for_contractor, lambda { |id|
    { :include => :fax_assignable_joins, :conditions => ["fax_assignable_joins.assignable_id = ? AND fax_assignable_joins.assignable_type = 'Contractor'", id] }
  }
  
  scope :for_customer, lambda { |id|
    { :include => :fax_assignable_joins, :conditions => ["fax_assignable_joins.assignable_id = ? AND fax_assignable_joins.assignable_type = 'Customer'", id] }
  }
  
  scope :unassigned, { 
    :conditions => 'faxes.id NOT IN (SELECT `fax_id` FROM fax_assignable_joins)'
  }
  
  scope :from_source_key, lambda { |key|
    { :conditions => {:source_id => FaxSource.find_by_key(key).id} }
  }
  
  scope :related_by_sender, lambda { |n|
    { :include => :fax_assignable_joins, :conditions => ["sender_fax_number = ? AND fax_assignable_joins.assignable_id != '' AND fax_assignable_joins.assignable_type != ''", n] }
  }
  
  def deduce_sender_fax_number_using_envelope(envelope)
    self.sender_fax_number = $installation.fax_service.deduce_sender_fax_number_using_envelope(envelope)
    self.valid_sender_fax_number?
  end

  def as_json(a=nil,b=nil)
    {
      :id => self.id,
      :received_at => self.received_at.in_time_zone(EST).strftime("%m/%d/%y %I:%M %p"),
      :formatted_sender_fax_number => self.formatted_sender_fax_number,
      :sender_fax_number => self.sender_fax_number,
      :assignables => self.assignables.collect { |a|
        {
          :id => a.id,
          :type => a.class.to_s,
          :summary => (a.nil? ? "Assignable is nil" : a.notification_summary)
        }
      }
    }
  end
  
  def pdf_path
    "#{Rails.root}/faxes/#{self.id}.pdf"
  end
  
  def preview_path
    "#{Rails.root}/faxes/previews/#{self.id}.png"
  end

  def thumbnail_path
    "#{Rails.root}/faxes/thumbnails/#{self.id}.png"
  end
  
  def write_pngs!
    if self.is_corrupt?
      self.write_corrupt!
    else
      list = Magick::ImageList.new(self.pdf_path)
      list[0].resize_to_fit(800).write(self.preview_path)
      list[0].resize_to_fit(64).write(self.thumbnail_path)
    end
  end
  
  def valid_sender_fax_number?
    (self.sender_fax_number =~ /^\d{10}$/) == 0 
  end
  
  def formatted_sender_fax_number
    "(#{self.sender_fax_number[0...3]}) #{self.sender_fax_number[3...6]}-#{self.sender_fax_number[6...10]}"
  end
  
  def edit_url; ''; end
  
  def notification_summary
    "#{self.source.name.singularize} Fax from #{self.formatted_sender_fax_number}"
  end
  
  def assignables
    FaxAssignableJoin.for_fax(self).collect(&:assignable)
  end
  
  def assignable_summaries
    self.assignables.collect(&:notification_summary)
  end
  
  def write_corrupt!
    base = "#{Rails.root}/faxes"
    list = Magick::ImageList.new("#{Rails.root}/app/assets/images/admin/corrupt_fax.png")
    list[0].write(self.preview_path)
    list[0].resize_to_fit(64).write(self.thumbnail_path)
    return self
  end
  
  def is_corrupt?
    base = "#{Rails.root}/faxes"
    pdf_size = File.size?(self.pdf_path)
    pdf_size = 0 unless pdf_size.present?
    is_corrupt = false
    if pdf_size < 1000
      # PDF is likely corrupt. Test first
      begin
        list = Magick::ImageList.new(self.pdf_path)
        if list[0].nil?
          self.write_corrupt!
          is_corrupt = true
        end
      rescue Magick::ImageMagickError
        is_corrupt = true
      end
    end
    return is_corrupt
  end
end
