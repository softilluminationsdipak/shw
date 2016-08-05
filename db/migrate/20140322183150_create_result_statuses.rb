class CreateResultStatuses < ActiveRecord::Migration
  def change
    create_table :result_statuses do |t|
      t.integer :csid
      t.string :result_code
      t.string :result_status
      t.boolean :active
      t.boolean :navigation
      t.string :color_code
      t.string :status_url

      t.timestamps
    end
  end
end
