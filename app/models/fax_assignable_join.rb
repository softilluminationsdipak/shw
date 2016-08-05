class FaxAssignableJoin < ActiveRecord::Base
  belongs_to :fax
  belongs_to :assignable, :polymorphic => true
  
  scope :for_fax, lambda { |f|
    { :conditions => { :fax_id => f.id } }
  }
end
