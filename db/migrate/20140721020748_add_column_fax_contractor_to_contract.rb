class AddColumnFaxContractorToContract < ActiveRecord::Migration
  def change
    add_attachment :contractors, :fax_or_invoice
    add_attachment :contractors, :note
  end
end
