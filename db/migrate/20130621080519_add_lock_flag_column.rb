class AddLockFlagColumn < ActiveRecord::Migration
  def up
    add_column :fax_sources,:lock_flag,:integer,:default => 0
  end

  def down
    remove_column :fax_sources,:lock_flag
  end
end
