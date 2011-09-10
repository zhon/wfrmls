module Wfrmls
  module Worker
    attr_accessor :worker_retry_check_count,
      :worker_queue

    DEFAULT_WORKER_RETRY_CHECK_COUNT = 4

    def run
      @worker_retry_check_count ||= DEFAULT_WORKER_RETRY_CHECK_COUNT
      @worker_state ||= :work
      case @worker_state
      when :work
        work
        @worker_state = :check_work
        @worker_queue.enq self if @worker_retry_check_count > 0
      when :check_work
        if @worker_retry_check_count > 0
          unless check_work
            @worker_queue.enq self
          end
        else
          @worker_state = :done
        end
        @worker_retry_check_count -= 1
      when :done
        # TODO if we are really done and here log someting
      end
    end

  end
end
