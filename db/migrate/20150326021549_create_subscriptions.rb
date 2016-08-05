class CreateSubscriptions < ActiveRecord::Migration
  def change
    create_table :subscriptions do |t|
      t.integer :credit_card_id
      t.datetime :start_date
      t.datetime :end_date
      t.string :amount
      t.string :interval
      t.string :occurances
      t.string :status
      t.integer :customer_id

      t.timestamps
    end
  end
end
