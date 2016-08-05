class AddColumnMinChargeToContractor < ActiveRecord::Migration
  def change
    add_column :contractors, :min_charge, 	:integer, :default => 0
    add_column :contractors, :lobor_rate, 	:float, 	:default => 0.0
    add_column :contractors, :parts_markup, :integer, :default => 0
  end
end
