class AddColumnPurchaseDateToCustomer < ActiveRecord::Migration
  def change
    add_column :customers, :purchase_date, :string
  end
end
