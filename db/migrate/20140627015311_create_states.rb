class CreateStates < ActiveRecord::Migration
  def change
    create_table :states do |t|
      t.string :name
      t.boolean :gaq, :default => false
      t.boolean :affiliate, :default => false
      t.boolean :api, :default => false
      t.timestamps
    end
  end
end
