class CreateGateways < ActiveRecord::Migration
  def change
    create_table :gateways do |t|
      t.string :gateway_type
      t.string :login_id
      t.string :password
      t.string :transaction_key
      t.timestamps
    end
  end
end
