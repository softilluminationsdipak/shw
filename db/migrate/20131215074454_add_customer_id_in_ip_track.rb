class AddCustomerIdInIpTrack < ActiveRecord::Migration
  def up
    add_column :ip_tracks, :customer_id, :integer
  end

  def down
    remove_column :ip_tracks, :customer_id
  end
end
