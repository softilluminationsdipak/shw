class FaxFetchWorker
  include Sidekiq::Worker
  sidekiq_options :retry => false

  def perform(job_id=0)
    begin
      logger.warn "perform is invoked."
    rescue
    end

    FaxSource.all.each do |source|
      if source.lock_flag == 0
        # before calling retrieve, update lock_flag to show that it has been already seized.
        source.lock_flag =1
        source.save
        begin
          logger.warn "source: #{source.inspect}"
          logger.warn "[#{Time.now}] FaxFetcherWorker::perform calling retrieve!."
          logger.warn "job_id: #{job_id}"
          logger.warn "**********************************************************************"
          source.retrieve!

          # after done, clear lock_flag, so other can seize it
          source.lock_flag =0
          source.save
          logger.warn "FaxFetcherWorker::perform is finished with retrieve!."
        rescue
        end
      end
    end
    begin
      logger.warn "perform is done.*************************************************"
    rescue
    end
    # FaxFetchWorker.perform_at(15.minutes, 0) # recalling after 15 minutes
  end
end
