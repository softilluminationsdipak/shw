class AddColumnAvatarToAttachent < ActiveRecord::Migration
  def change
    add_attachment :attachments, :avatar
  end
end
