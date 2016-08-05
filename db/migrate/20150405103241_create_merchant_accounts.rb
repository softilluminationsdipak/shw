class CreateMerchantAccounts < ActiveRecord::Migration
  def change
    create_table :merchant_accounts do |t|
      t.string :username
      t.string :password
      t.string :merchant_type
      t.string :token
      t.string :merchant_name
      t.timestamps
    end
  end
end
