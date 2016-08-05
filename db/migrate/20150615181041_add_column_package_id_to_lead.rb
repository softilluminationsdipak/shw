class AddColumnPackageIdToLead < ActiveRecord::Migration
  def change
    add_column :leads, :package_id, :integer
  end
end
