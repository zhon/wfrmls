module Wfrmls
  module Worker
    DEFAULT_WORKER_RETRY_CHECK_COUNT = 1

    def run
      @worker_state ||= :work
      case @worker_state
      when :work
        work
        @worker_state = :check_work
        @worker_queue.enq self if 0 < @worker_retry_check_count
      when :check_work
        if @worker_retry_check_count > 0
          unless check_work
            @worker_queue.enq self
          end
        else
          @worker_state = :done
        end
        @worker_retry_check_count =- 1
      when :done
        # TODO if we are really done and here log someting
      end
    end

  end
end
