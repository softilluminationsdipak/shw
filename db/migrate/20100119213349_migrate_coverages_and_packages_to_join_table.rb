class MigrateCoveragesAndPackagesToJoinTable < ActiveRecord::Migration
  def self.up
    names = [ 'A/C, Cooling', 'Heating System', 'Electrical System', 'Plumbing system',
              'Water Heater', 'Ductwork', 'Plumbing Stoppage', 'Clothes Washer',
              'Clothes Dryer', 'Refrigerator', 'Stove/Oven', 'Microwave Oven(Built In)',
              'Garbage Disposal', 'Dishwasher', 'Ceiling Fans', 'Garage Door Opener'
            ]
    packages = {
      1 => names,
      3 => names[0...6],
      4 => names[7...14]
    }
    #say_with_time "Relating Coverages to Packages" do
    #  packages.each do |id, coverage_names|
    #    package = Package.find(id)
    #    package.coverages = coverage_names.collect { |n| Coverage.find_by_coverage_name(n) }
    #    say "#{package.package_name}.coverages = #{package.coverages.collect(&:coverage_name).join(', ')}", true
    #  end
    #end
  end

  def self.down
    say_with_time "Clearing Package-Coverage relationships" do
      Package.each { |p| p.coverages.clear; say p.package_name, true }
    end
  end
end
