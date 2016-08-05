class AddColumnMinClaimToClaim < ActiveRecord::Migration
  def change
    add_column :claims, :min_claim, :decimal, :precision => 10, :scale => 2
  end
end
