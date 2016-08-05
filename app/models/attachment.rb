class Attachment < ActiveRecord::Base
  ## Relationship
  attr_accessible :attachable_id, :attachable_type, :attach_url, :avatar
  belongs_to :attachable, :polymorphic => true

  Paperclip.interpolates :attached_to do |attachment, style|
    attachment.instance.attachable.class.to_s.downcase
  end

  Paperclip.interpolates :year do |attachment, style|
    Time.now.year.to_s.downcase
  end

  ## Paperclip with amazone s3
  has_attached_file :avatar,
    :storage => :s3,
    :s3_credentials => "#{Rails.root}/config/amazon_s3.yml",
    :path => "/#{Rails.env}/:attached_to/:year/:id/:filename"
  
  ## Validations
  validates_attachment :avatar, content_type: { content_type: ["image/jpeg", "image/gif", "image/png", "application/pdf"] }
  
end
