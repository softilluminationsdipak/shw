class ChangeColumnMinRateToContractor < ActiveRecord::Migration
  def up
  	change_column :contractors, :min_charge, :decimal, :precision => 10, :scale => 2
  end

  def down
  	change_column :contractors, :min_charge, :integer
  end
end
