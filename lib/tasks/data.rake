namespace :data do
  task :remove_spaces_in_contractors_table => :environment do
    Contractor.all.each do |contractor|
      contractor.company = contractor.company.lstrip
      contractor.phone = contractor.phone.lstrip
      contractor.first_name = contractor.first_name.lstrip
      contractor.last_name = contractor.last_name.lstrip
      contractor.job_title = contractor.job_title.lstrip
      contractor.save
    end
  end
  
  task :update_sentence_case => :environment do
    Contractor.all.each do |contractor|
      contractor.company = contractor.company.capitalize
      contractor.phone = contractor.phone.capitalize
      contractor.first_name = contractor.first_name.capitalize
      contractor.last_name = contractor.last_name.capitalize
      contractor.job_title = contractor.job_title.capitalize
      contractor.save
    end
  end

end
