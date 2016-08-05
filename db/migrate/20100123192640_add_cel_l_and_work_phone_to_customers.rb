class AddCelLAndWorkPhoneToCustomers < ActiveRecord::Migration
  def self.up
    add_column :customers, :work_phone, :string
    add_column :customers, :mobile_phone, :string
  end

  def self.down
    remove_column :customers, :work_phone
    remove_column :customers, :mobile_phone
  end
end
