class ChangeColumnEstimateToClaim < ActiveRecord::Migration
  def up
  	change_column :claims, :service_call_fee, :decimal, :precision => 10, :scale => 2
  	change_column :claims, :estimate, :decimal, :precision => 10, :scale => 2
  end

  def down
  	change_column :contractors, :service_call_fee, :string
  	change_column :contractors, :estimate, :string
  end
end
