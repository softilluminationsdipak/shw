class Permission < ActiveRecord::Base
  attr_accessible :action_name, :is_admin_access, :module_name, :is_sales_access, :is_claim_access, :is_affilate_access, :action_description 

  ## Scopes
  scope :admin_access, where('is_admin_access = ?', true)
  scope :sales_access, where('is_sales_access = ?', true)
  scope :claim_access, where('is_claim_access = ?', true)
  scope :affilate_access, where('is_affilate_access = ?', true)

  scope :admin_retriction, where('is_admin_access = ?', false)
  scope :sales_retriction, where('is_sales_access = ?', false)
  scope :claim_retriction, where('is_claim_access = ?', false)
  scope :affilate_retriction, where('is_affilate_access = ?', false)

  def notification_summary
    "Change Permission For - #{self.module_name} for #{self.action_name}"
  end
  
  def edit_url
    "/admin/permissions/edit/#{self.id}"
  end
end
