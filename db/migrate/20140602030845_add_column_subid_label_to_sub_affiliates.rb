class AddColumnSubidLabelToSubAffiliates < ActiveRecord::Migration
  def change
    add_column :sub_affiliates, :subid_label, :string
    add_column :sub_affiliates, :track_link, :string
  end
end
