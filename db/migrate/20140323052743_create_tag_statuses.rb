class CreateTagStatuses < ActiveRecord::Migration
  def change
    create_table :tag_statuses do |t|
      t.integer   :csid
      t.string    :tag_code
      t.string    :tag_status
      t.boolean   :active
      t.boolean   :navigation
      t.string    :color_code
      t.string    :status_url
      t.timestamps
    end
  end
end
