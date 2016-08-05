class AddColumnSubscriptionidAndTransactionidToTransaction < ActiveRecord::Migration
  def change
    add_column :transactions, :subscriptionid, :string
    add_column :transactions, :transactionid, :string
  end
end
