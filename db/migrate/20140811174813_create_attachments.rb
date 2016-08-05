class CreateAttachments < ActiveRecord::Migration
  def change
    create_table :attachments do |t|
      t.integer  :attachable_id
      t.string 	 :attachable_type
      t.text 		 :attach_url
      t.timestamps
    end
  end
end
