class AddColumnReleaseSentToClaim < ActiveRecord::Migration
  def change
    add_column :claims, :release_sent, :datetime
  end
end
