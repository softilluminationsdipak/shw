class AddColumnIsTosToContent < ActiveRecord::Migration
  def change
    add_column :content, :is_tos, :boolean, :default => false
  end
end
