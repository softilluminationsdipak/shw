class CreateIpTracks < ActiveRecord::Migration
  def change
    create_table :ip_tracks do |t|
      t.string :remote_ip, null: false
      t.string :source_format
      t.string :browser_title
      t.string :os_title
      t.string :country_code
      t.string :country_name
      t.string :city
      t.string :region_name
      t.string :zip_code
      t.float :longitude
      t.float :latitude
      t.string :timezone
      t.timestamps
    end
  end
end

