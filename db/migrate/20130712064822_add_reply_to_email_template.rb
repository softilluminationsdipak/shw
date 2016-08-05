class AddReplyToEmailTemplate < ActiveRecord::Migration
  def change
    add_column :email_templates, :reply_to, :string
  end
end
