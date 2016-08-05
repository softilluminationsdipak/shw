class AddColumnSubidToCustomer < ActiveRecord::Migration
  def change
    add_column :customers, :subid, :string
  end
end
