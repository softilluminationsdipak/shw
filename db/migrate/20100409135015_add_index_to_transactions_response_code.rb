class AddIndexToTransactionsResponseCode < ActiveRecord::Migration
  def self.up
    add_index "transactions", ["response_code"], :name => "response_code_index"
  end

  def self.down
    remove_index :response_code_index
  end
end
