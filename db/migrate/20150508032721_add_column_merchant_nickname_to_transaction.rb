class AddColumnMerchantNicknameToTransaction < ActiveRecord::Migration
  def change
    add_column :transactions, :merchant_nickname, :string
  end
end
