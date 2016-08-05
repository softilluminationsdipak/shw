class AddColumnMinClaimAndMinHourToContractor < ActiveRecord::Migration
  def change
    add_column :contractors, :min_claim, :decimal, :precision => 10, :scale => 2
    add_column :contractors, :min_hour, :decimal, :precision => 10, :scale => 2
  end
end
