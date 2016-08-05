class AddColumnAddressToPartner < ActiveRecord::Migration
  def change
    add_column :partners, :address1, :string
    add_column :partners, :address2, :string
    add_column :partners, :city, 		 :string
    add_column :partners, :state, 	 :string
    add_column :partners, :zipcode,	 :string
  end
end
