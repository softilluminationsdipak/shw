class SubAffiliate < ActiveRecord::Base
  attr_accessible :partner_id, :sub_ids, :subid_label, :track_link
  belongs_to :partner
  has_many :customers

  validates_presence_of :sub_ids
  validates_uniqueness_of :sub_ids

  def secure_randon_string
  	require 'securerandom' 
  	return SecureRandom.hex(4)
  end
end
