class AddColumnYearToCustomer < ActiveRecord::Migration
  def change
    add_column :customers, :year, :integer, default: 0
  end
end
