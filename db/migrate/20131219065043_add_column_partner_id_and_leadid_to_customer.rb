class AddColumnPartnerIdAndLeadidToCustomer < ActiveRecord::Migration
  def change
    add_column :customers, :partner_id, :integer
    add_column :customers, :leadid, :string
  end
end
