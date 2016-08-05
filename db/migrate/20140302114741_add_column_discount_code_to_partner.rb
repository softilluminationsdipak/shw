class AddColumnDiscountCodeToPartner < ActiveRecord::Migration
  def change
    add_column :partners, :discount_code, :string
  end
end
