class AddColumnPaymentTypeToTransaction < ActiveRecord::Migration
  def change
    add_column :transactions, :payment_type, :string, :default => "Auth.net"
  end
end
