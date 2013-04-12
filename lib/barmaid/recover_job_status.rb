module Barmaid
  class RecoverJobStatus
    attr_accessor :status
    attr_accessor :time
    attr_accessor :message
    attr_accessor :pct_complete
    attr_accessor :server
    attr_accessor :target
    attr_accessor :backup_id
    attr_accessor :completed_at
    attr_accessor :id

    def initialize
    end

    def self.create(status_hash)
      job_status = RecoverJobStatus.new
      job_status.status = status_hash.status
      job_status.time = status_hash.time
      job_status.message = status_hash.message || ""
      job_status.pct_complete = status_hash.pct_complete
      job_status.completed_at = status_hash["completed_at"] || ""
      job_status.id = status_hash.uuid

      if status_hash["options"]
        job_status.server = status_hash["options"]["server"]
        job_status.target = status_hash["options"]["target"]
        job_status.backup_id = status_hash["options"]["backup_id"]
      end

      return job_status
    end
  end

  class RecoverJobStatuses < Array
    def initialize(statuses_hash)
      statuses_hash.each do |status|
        self << RecoverJobStatus.create(status)
      end
    end
  end
end
