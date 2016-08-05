class DeleteSampleContract < ActiveRecord::Migration
  def self.up
    Content.find_by_slug('sample_contract').destroy
  end

  def self.down
  end
end
