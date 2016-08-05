class AddColumnCtrCheckToClaim < ActiveRecord::Migration
  def change
    add_column :claims, :ctr_check, :integer
    add_column :claims, :ctr_check_date, :date
    add_column :claims, :rel_check, :integer
    add_column :claims, :rel_check_date, :date

  end
end
