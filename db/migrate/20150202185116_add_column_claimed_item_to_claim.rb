class AddColumnClaimedItemToClaim < ActiveRecord::Migration
  def change
    add_column :claims, :claimed_item, :string
  end
end
