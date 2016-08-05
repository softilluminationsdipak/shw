class AddObjectIdToFaxes < ActiveRecord::Migration
  def change
    add_column :faxes, :object_id,:string
  end
end
