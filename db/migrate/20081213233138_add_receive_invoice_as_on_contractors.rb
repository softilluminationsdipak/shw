class AddReceiveInvoiceAsOnContractors < ActiveRecord::Migration
  def self.up
    add_column :contractors, :receive_invoice_as, :string, :default => 'email'
  end

  def self.down
  	remove_column :contractors, :receive_invoice_as
  end
end
