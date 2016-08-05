class CreateLeadStatuses < ActiveRecord::Migration
  def change
    create_table :lead_statuses do |t|
      t.integer :csid
      t.string :lead_code
      t.string :lead_status
      t.boolean :active
      t.boolean :navigation
      t.string :color_code

      t.timestamps
    end
  end
end
