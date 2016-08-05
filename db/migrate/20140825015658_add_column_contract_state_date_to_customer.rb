class AddColumnContractStateDateToCustomer < ActiveRecord::Migration
  def change
    add_column :customers, :contract_start_date, :date
    add_column :customers, :contract_duration, :integer, :default => 0
    add_column :customers, :total_billed, :decimal, :precision => 10, :scale => 2
  end
end
