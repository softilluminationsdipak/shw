class AddColumnDatetimestampToCustomer < ActiveRecord::Migration
  def change
    add_column :customers, :datetimestamp, :datetime
  end
end
