class AddColumnLicenseNumberToContractor < ActiveRecord::Migration
  def change
    add_column :contractors, :license_number, :string
    add_column :contractors, :insured, :boolean, :default => false
  end
end
