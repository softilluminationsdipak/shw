class AddColumnIsDeleteToContent < ActiveRecord::Migration
  def change
    add_column :content, :is_delete, :boolean, :default => false
  end
end
