class AddColumnPolicySignedToCustomer < ActiveRecord::Migration
  def change
    add_column :customers, :policy_signed, :boolean, :default => false
  end
end
