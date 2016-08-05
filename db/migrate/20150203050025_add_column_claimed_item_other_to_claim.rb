class AddColumnClaimedItemOtherToClaim < ActiveRecord::Migration
  def change
    add_column :claims, :other_claimed_item, :string
  end
end
