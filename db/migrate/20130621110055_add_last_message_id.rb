class AddLastMessageId < ActiveRecord::Migration
  def up
    add_column :fax_sources,:last_scanned_id,:integer,:default => 500
  end

  def down
    remove_column :fax_sources,:last_scanned_id
  end
end
