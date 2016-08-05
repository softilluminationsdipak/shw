class CreateSubmitclaims < ActiveRecord::Migration
  def change
    create_table :submitclaims do |t|
      t.string :name
      t.string :policy_number
      t.string :issue_type
      t.string :issue_description
      t.string :phone_number
      t.string :email
      t.string :address
      t.string :city
      t.string :state
      t.string :zipcode
      t.string :ip_address

      t.timestamps
    end
  end
end
