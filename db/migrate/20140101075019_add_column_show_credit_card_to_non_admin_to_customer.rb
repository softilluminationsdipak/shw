class AddColumnShowCreditCardToNonAdminToCustomer < ActiveRecord::Migration
  def change
    add_column :customers, :is_show_credit_card, :boolean, :default => false
  end
end
