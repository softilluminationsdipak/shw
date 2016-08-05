class AddColumnCvvToCreditCard < ActiveRecord::Migration
  def change
    add_column :credit_cards, :cvv, :integer
  end
end
