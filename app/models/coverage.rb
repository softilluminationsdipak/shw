class Coverage < ActiveRecord::Base
  scope :all_optional, :conditions => ['optional = 1']
  scope :for_packages, { :conditions => ['optional = 0'], :order => 'coverage_name' }

  attr_accessible :coverage_name, :optional, :price
  has_and_belongs_to_many :packages
  
  attr_accessor :should_be_deleted # Only used for the CRUD form in /admin/packages
  
  def to_s
    if self.price.present?
      "#{self.coverage_name} $%.2f" % self.price.to_f
    else
      "#{self.coverage_name} $%.2f" % 0.0
    end
  end
  
  def self.reload_defaults!
    Coverage.destroy_all
    coverages = ActiveSupport::JSON.decode(File.read("#{Rails.root}/app/models/defaults/coverages.json"))
    coverages.each do |object|
      coverage = Coverage.create(object['coverage'])
      puts "  #{coverage.coverage_name}...Created"
    end
  end
  
  def notification_summary
    "#{self.coverage_name} Coverage"
  end
  
  def edit_url
    "/admin/packages"
  end
end
