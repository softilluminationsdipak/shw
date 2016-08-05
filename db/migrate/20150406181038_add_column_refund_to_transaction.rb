class AddColumnRefundToTransaction < ActiveRecord::Migration
  def change
    add_column :transactions, :refund, :float, :default => 0.00
  end
end
