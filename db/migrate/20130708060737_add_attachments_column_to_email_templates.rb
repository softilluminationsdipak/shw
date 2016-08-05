class AddAttachmentsColumnToEmailTemplates < ActiveRecord::Migration
  def up
    add_column :email_templates, :attachments, :string
  end

  def down
    remove_column :email_templates, :attachments
  end
end
