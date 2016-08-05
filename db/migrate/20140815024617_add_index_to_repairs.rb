class AddIndexToRepairs < ActiveRecord::Migration
  def change
    add_index :repairs, :claim_id
    add_index :repairs, :contractor_id
  end
end
