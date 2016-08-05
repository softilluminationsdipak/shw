class AddColumnUpdateByToCustomer < ActiveRecord::Migration
  def change
    add_column :customers, :update_by, :string
  end
end
