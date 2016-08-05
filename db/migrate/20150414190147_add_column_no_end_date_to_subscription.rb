class AddColumnNoEndDateToSubscription < ActiveRecord::Migration
  def change
    add_column :subscriptions, :no_end_date, :boolean, :default => false
  end
end
