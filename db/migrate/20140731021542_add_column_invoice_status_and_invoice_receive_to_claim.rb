class AddColumnInvoiceStatusAndInvoiceReceiveToClaim < ActiveRecord::Migration
  def change
    add_column :claims, :invoice_status, :string
    add_column :claims, :invoice_receive, :datetime
  end
end
