=begin
class FaxFetcherWorker < BackgrounDRb::MetaWorker
  set_worker_name :fax_fetcher_worker
  def create(args = nil)
    Notification.notify(Notification::INFO, :subject_summary => "Fax Fetcher", :message => 'started')
    FaxSource.each do |source|
      add_periodic_timer(15.minutes) { source.retrieve! }
      Notification.notify(Notification::INFO, :subject_summary => "Next retrieval of #{source.key.humanize.capitalize} faxes at #{60.minutes.from_now.in_time_zone(EST).strftime('%I:%M%p')}", :message => '')
    end
  end
end
=end

class FaxFetcherWorker
  #set_worker_name :fax_fetcher_worker
 	include Sidekiq::Worker
	sidekiq_options :retry => false
  #def create(args = nil)
  def perform(args = nil)
    Notification.notify(Notification::INFO, :subject_summary => "Fax Fetcher", :message => 'started')
    FaxSource.each do |source|
      add_periodic_timer(15.minutes) { source.retrieve! }
      Notification.notify(Notification::INFO, :subject_summary => "Next retrieval of #{source.key.humanize.capitalize} faxes at #{60.minutes.from_now.in_time_zone(EST).strftime('%I:%M%p')}", :message => '')
    end
  end
end


