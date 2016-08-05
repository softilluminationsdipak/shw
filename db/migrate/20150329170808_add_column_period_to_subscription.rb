class AddColumnPeriodToSubscription < ActiveRecord::Migration
  def change
    add_column :subscriptions, :period, :string
  end
end
