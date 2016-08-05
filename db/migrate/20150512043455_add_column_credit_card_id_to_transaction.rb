class AddColumnCreditCardIdToTransaction < ActiveRecord::Migration
  def change
    add_column :transactions, :credit_card_id, :integer
  end
end
