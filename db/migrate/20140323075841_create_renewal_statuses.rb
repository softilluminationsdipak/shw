class CreateRenewalStatuses < ActiveRecord::Migration
  def change
    create_table :renewal_statuses do |t|
      t.integer :csid
      t.string :renewal_code
      t.string :renewal_status
      t.boolean :active
      t.boolean :navigation
      t.string :color_code
      t.string :status_url

      t.timestamps
    end
  end
end
