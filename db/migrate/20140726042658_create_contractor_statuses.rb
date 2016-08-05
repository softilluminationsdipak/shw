class CreateContractorStatuses < ActiveRecord::Migration
  def change
    create_table :contractor_statuses do |t|
      t.integer :csid
      t.string  :contractor_code
      t.string  :contractor_status
      t.boolean :active, :default => false
      t.boolean :navigation, :default => false
      t.timestamps
    end
  end
end
