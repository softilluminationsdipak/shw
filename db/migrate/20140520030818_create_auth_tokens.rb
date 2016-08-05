class CreateAuthTokens < ActiveRecord::Migration
  def change
    create_table :auth_tokens do |t|
      t.integer :partner_id
      t.string :auth_token
      t.string :discount_code
      t.timestamps
    end
  end
end
