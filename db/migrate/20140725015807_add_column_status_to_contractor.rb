class AddColumnStatusToContractor < ActiveRecord::Migration
  def change
    add_column :contractors, :status, :string
  end
end
