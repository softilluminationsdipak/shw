class CreateClaimStatuses < ActiveRecord::Migration
  def change
    create_table :claim_statuses do |t|
      t.integer :csid
      t.string :claim_code
      t.string :claim_status
      t.boolean :active
      t.boolean :navigation
      t.string :color_code
      t.string :claim_url
      t.timestamps
    end
  end
end
