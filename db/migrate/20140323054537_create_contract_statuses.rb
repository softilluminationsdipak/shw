class CreateContractStatuses < ActiveRecord::Migration
  def change
    create_table :contract_statuses do |t|
      t.integer :csid
      t.string :contract_code
      t.string :contract_status
      t.boolean :active
      t.boolean :navigation
      t.string :color_code
      t.string :status_url

      t.timestamps
    end
  end
end
