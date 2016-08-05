class AddColumnProviderUidOauthTokenOauthExpiresAtToPartner < ActiveRecord::Migration
  def change
    add_column :partners, :provider, :string
    add_column :partners, :uid, :string
    add_column :partners, :oauth_token, :string
    add_column :partners, :oauth_expires_at, :datetime
  end
end
