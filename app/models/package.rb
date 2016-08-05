class Package < ActiveRecord::Base
  has_many :customers
  has_and_belongs_to_many :coverages
  
  HOME_TYPES = ['single', 'condo', 'duplex', 'triplex', 'fourplex'].freeze
  @@home_type_names = {
    'single' => "Single-Family",
    'condo'  => 'Condominium',
    'duplex' => '2-Family',
    'triplex' => '3-Family',
    'fourplex' => '4-Family'
  }
  def self.home_type_names; @@home_type_names; end
  
  def covers
    self.coverages.collect(&:coverage_name).join(', ')
  end
end
