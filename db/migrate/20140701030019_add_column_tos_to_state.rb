class AddColumnTosToState < ActiveRecord::Migration
  def change
    add_column :states, :tos, :integer
  end
end
