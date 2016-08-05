class CreateMissingRenewalDates < ActiveRecord::Migration
  def change
    create_table :missing_renewal_dates do |t|
      t.integer :customer_id
      t.string :fullname
      t.string :customer_state
      t.integer :no_of_transaction
      t.float :total
      t.string :cdate
      t.timestamps
    end
  end
end
