class AddColumnDeletedToPartners < ActiveRecord::Migration
  def change
    add_column :partners, :deleted_at, :datetime
  end
end
