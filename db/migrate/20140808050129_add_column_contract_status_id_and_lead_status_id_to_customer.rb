class AddColumnContractStatusIdAndLeadStatusIdToCustomer < ActiveRecord::Migration
  def change
    add_column :customers, :contract_status_id, :integer
    add_column :customers, :lead_status_id, :integer
  end
end
