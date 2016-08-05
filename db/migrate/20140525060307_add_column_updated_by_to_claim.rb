class AddColumnUpdatedByToClaim < ActiveRecord::Migration
  def change
    add_column :claims, :updated_by, :string
  end
end
