class AddLockedToEmailTemplates < ActiveRecord::Migration
  def self.up
   	create_table :email_templates do |t|
  		t.string :name
  		t.text 	:subject
  		t.text :body
  		t.boolean :locked, :default => false
    end
  end

  def self.down
  	drop_table :email_templates
  end
end