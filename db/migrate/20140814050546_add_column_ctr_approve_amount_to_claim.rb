class AddColumnCtrApproveAmountToClaim < ActiveRecord::Migration
  def change
    add_column :claims, :ctr_approve_amount, :decimal, :precision => 10, :scale => 2
  end
end
