class CreateProperties < ActiveRecord::Migration
  def self.up
    create_table :properties do |t|
      t.integer :customer_id
      t.string  :address
      t.string  :city
      t.string  :state
      t.string  :zip
      t.timestamps
    end
    create_table :admin_users do |t|
      t.string    :email
      t.string    :encrypted_password
      t.string    :reset_password_token
      t.datetime  :reset_password_sent_at
      t.datetime  :remember_created_at
      t.integer   :sign_in_count
      t.datetime  :current_sign_in_at
      t.datetime  :last_sign_in_at
      t.string    :current_sign_in_ip
      t.string    :last_sign_in_ip
      t.string    :role
      t.timestamps
    end
  end

  create_table :referals, :primary_key => "referal_id", :force => true do |t|
    t.string  :referal_text, :default => "", :null => false
    t.integer :timestamp,    :default => 0,  :null => false
  end

  def self.down
    drop_table :properties
    drop_table :admin_users
    drop_table :referals
  end
end