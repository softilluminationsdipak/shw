class AddColumnTrackingLinkToPartner < ActiveRecord::Migration
  def change
    add_column :partners, :tracking_link, :text
  end
end
