class AddColumnOptionalCoveragesToLeads < ActiveRecord::Migration
  def change
    add_column :leads, :optional_coverages, :text
    add_column :leads, :discount_code, :string
    add_column :leads, :credit_card_number, :string
    add_column :leads, :exp_date, :string
    add_column :leads, :billing_address, :string
    add_column :leads, :billing_name, :string
    add_column :leads, :billing_city, :string
    add_column :leads, :billing_state, :string
    add_column :leads, :billing_zipcode, :string
    add_column :leads, :payment_method, :integer
  end
end
