require 'activejob-status/storage'
require 'activejob-status/status'
require 'activejob-status/progress'
require 'ostruct'

module ActiveJob::Status
  extend ActiveSupport::Concern
  DEFAULT_EXPIRY = 60 * 30

  included do
    before_enqueue {|job| job.status.update(status: :queued) }
    before_perform {|job| job.status.update(status: :working) }
    after_perform  {|job| job.status.update(status: :completed) }

    rescue_from(Exception) do |e|
      self.status.update(status: :failed)
      raise e
    end
  end

  def status
    @status ||= Status.new(self)
  end

  def progress
    @progress ||= Progress.new(self)
  end

  class << self
    def store= store
      store = ActiveSupport::Cache.lookup_store(store) if store.is_a?(Symbol)
      @@store = store
    end

    def store
      @@store ||= (defined?(Rails) && Rails.cache)
    end

    def get(id)
      OpenStruct.new({
        status: Status.new(id),
        progress: Progress.new(id)
      })
    end
  end
end
