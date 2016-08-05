class AddPaymentScheduleOverride < ActiveRecord::Migration
  def self.up
    add_column :customers, :payment_schedule_override, :string
  end

  def self.down
    remove_column :customers, :payment_schedule_override
  end
end
