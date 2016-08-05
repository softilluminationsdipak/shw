class DatabaseDefaults
  MODEL_DEFAULTS_PATH = "#{Rails.root}/app/models/defaults"

  def self.cancellation_reasons
    reasons = ActiveSupport::JSON.decode(File.read("#{MODEL_DEFAULTS_PATH}/cancellation_reasons.json"))
    reasons.each do |object|
      reason = CancellationReason.create(object)
      puts "  #{reason.reason}...Created"
    end

  end

  def self.contractors
    contractors = ActiveSupport::JSON.decode(File.read("#{MODEL_DEFAULTS_PATH}/contractors.json"))
    puts "  #{contractors.length} Contractors will be imported from #{path}"
    contractors.each do |object|
      address_object = object.delete('address')
      object.delete('id')
      print "  #{object['company']}..."
      if Contractor.find_by_company(object['company'])
        print "Exists\n"
        next
      end
      contractor = Contractor.create(object)
      print 'Created'
      if address_object
        address_object.delete('id')
        address_object.delete('string')
        address_object.delete('geocoded')
        address = contractor.build_address(address_object)
        address.should_skip_verification_and_geocoding = true
        address.save
        print ' with Address'
      end
      print "\n"
      $stdout.flush
    end
  end

  def self.coverages
    Coverage.destroy_all
    coverages = ActiveSupport::JSON.decode(File.read("#{Rails.root}/app/models/defaults/coverages.json"))
    coverages.each do |object|
      coverage = Coverage.create(object['coverage'])
      puts "  #{coverage.coverage_name}...Created"
    end
  end

  def self.packages
    packages = ActiveSupport::JSON.decode(File.read("#{MODEL_DEFAULTS_PATH}/packages.json"))
    packages.each do |object|
      package = Package.create(object['package'])
      puts "  #{package.package_name}...Created"
    end

  end
end