class AddColumnApproveAmountToClaim < ActiveRecord::Migration
  def change
    add_column :claims, :approve_amount, :decimal, :precision => 10, :scale => 2
  end
end
