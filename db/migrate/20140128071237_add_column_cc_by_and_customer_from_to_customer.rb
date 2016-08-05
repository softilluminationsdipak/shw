class AddColumnCcByAndCustomerFromToCustomer < ActiveRecord::Migration
  def change
    add_column :customers, :cc_by, :string, :default => ""
    add_column :customers, :customer_from, :string, :default => ""
  end
end
