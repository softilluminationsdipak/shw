class AddColumnLastUpdateByToContractor < ActiveRecord::Migration
  def change
    add_column :contractors, :last_update_by, :string
  end
end
