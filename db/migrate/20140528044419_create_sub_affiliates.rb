class CreateSubAffiliates < ActiveRecord::Migration
  def change
    create_table :sub_affiliates do |t|
      t.integer :partner_id
      t.string :sub_ids

      t.timestamps
    end
  end
end
