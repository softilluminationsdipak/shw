class AddNotesOverride < ActiveRecord::Migration
  def self.up
    add_column :customers, :notes_override, :string
  end

  def self.down
    remove_column :customers, :notes_override
  end
end
