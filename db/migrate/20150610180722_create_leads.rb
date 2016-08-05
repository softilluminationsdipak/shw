class CreateLeads < ActiveRecord::Migration
  def change
    create_table :leads do |t|
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :work_phone
      t.string :mobile_phone
      t.string :home_phone
      t.string :address
      t.string :city
      t.string :state
      t.string :zipcode
      t.string :type_of_home
      t.string :square_footage

      t.timestamps
    end
  end
end
