class AddColumnSubscriptionIdToTransaction < ActiveRecord::Migration
  def change
    add_column :transactions, :sub_id, :integer
  end
end
