class AddColumnReleaseReceivedAndReleasePaidToClaim < ActiveRecord::Migration
  def change
    add_column :claims, :release_received, :datetime
    add_column :claims, :release_paid, :datetime
  end
end
