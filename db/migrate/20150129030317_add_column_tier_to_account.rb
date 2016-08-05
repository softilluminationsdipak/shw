class AddColumnTierToAccount < ActiveRecord::Migration
  def change
    add_column :accounts, :tier, :integer, default: 1
  end
end
