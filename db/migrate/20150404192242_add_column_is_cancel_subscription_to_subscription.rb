class AddColumnIsCancelSubscriptionToSubscription < ActiveRecord::Migration
  def change
    add_column :subscriptions, :is_cancel_subscription, :boolean, :default => false
  end
end
