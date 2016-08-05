class AddAdditionalSpa < ActiveRecord::Migration
  def self.up
    create_table :coverages do |t|
      t.string :coverage_name
      t.integer :optional, :default => 0 
      t.float :price
      t.timestamps
    end

    #Coverage.create({
  	#	:coverage_name => "Additional Spa",
  	#	:optional => 1,
  		#:premier => 0,
  	#	:price => 119.95
  		#:pack_1 => 0, :pack_2 => 0, :pack_3 => 0, :pack_4 => 0,
  		#:sort_order => 0
  	#})
    Coverage.create(:coverage_name => 'Additional Spa', :optional => 1, :price => 119.95)
  end

  def self.down
    Coverage.find(:first, :conditions => { :coverage_name => "Additional Spa "}).destroy
  end
end
