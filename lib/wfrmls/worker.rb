module Wfrmls
  module Worker
    DEFAULT_WORKER_RETRY_CHECK_COUNT = 1

    def run
      @worker_state ||= :work
      case @worker_state
      when :work
        work
        @worker_state = :check_work
        @worker_queue.enq self
      when :check_work
        unless check_work
          @worker_queue.enq self
        end
        @worker_retry_check_count =- 1
        @worker_state = :done if 0 >= @worker_retry_check_count
      when :done
        # TODO if we are really done and here log someting
      end
    end

  end
end
