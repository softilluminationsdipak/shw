class AddColumnMonthFeeToCustomer < ActiveRecord::Migration
  def change
    add_column :customers, :month_fee, :integer, :default => 0
  end
end
