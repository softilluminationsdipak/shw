class AddCallBackOnToCustomers < ActiveRecord::Migration
  def change
    add_column :customers, :call_back_on, :date
  end
end
