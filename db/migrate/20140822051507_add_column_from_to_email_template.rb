class AddColumnFromToEmailTemplate < ActiveRecord::Migration
  def change
    add_column :email_templates, :from, :string, :default => "info@selecthomewarranty.com"
  end
end
