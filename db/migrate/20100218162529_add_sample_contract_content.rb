class AddSampleContractContent < ActiveRecord::Migration
  def self.up
    Content.create({
      :slug => 'sample_contract',
      :html => Content.for('terms_and_conditions')
    })
  end

  def self.down
    Content.find_by_slug('sample_contract').destroy
  end
end
