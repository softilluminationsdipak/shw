class AddColumnContractApplicationStatusToContractor < ActiveRecord::Migration
  def change
    add_column :contractors, :contract_application_status, :string
  end
end
