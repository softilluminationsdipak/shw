class CreateCustomerStatuses < ActiveRecord::Migration
  def change
    create_table :customer_statuses do |t|
      t.integer :csid
      t.string :customer_code
      t.string :customer_status
      t.boolean :active
      t.boolean :navigation
      t.string :color_code
      t.string :status_url
      t.timestamps
    end
  end
end
