
require 'wfrmls/worker'

require 'test/unit'
require 'flexmock/test_unit'

module Wfrmls
  class WorkerTest < Test::Unit::TestCase

    def setup
      create
    end

    def test_calling_run_calls_work
      @worker.should_receive :work
      @worker.run
    end

    def test_worker_calls_check_run_on_second_run
      @worker.should_receive(:work).once
      @worker.should_receive(:check_work).once.ordered
      @worker.run
      @worker.run
    end

    def test_run_enques_self
      @worker.should_receive(:work).once
      @queue.should_receive(:enq).once
      @worker.run
    end

    def test_failed_check_should_enq_until_returning_true
      create(4)
      @worker.should_receive(:work)
      @worker.should_receive(:check_work).times(3).and_return(false,false,true)
      @queue.should_receive(:enq).times(3)
      @worker.run
      @worker.run
      @worker.run
      @worker.run
    end

    def test_failed_check_should_enq_until_retry_check_count_reached
      create(2)
      @worker.should_receive(:work)
      @worker.should_receive(:check_work).times(2).and_return(false,false)
      @queue.should_receive(:enq).times(3)
      @worker.run
      @worker.run
      @worker.run
      @worker.run
      @worker.run
    end

    def test_0_retry_check_count_should_never_run_check_work
      create(0)
      @worker.should_receive(:work)
      @worker.should_receive(:check_work).never
      @worker.run
      @worker.run
    end

    def test_0_retry_check_count_should_never_enque
      create(0)
      @worker.should_receive(:work)
      @queue.should_receive(:enq).never
      @worker.run
      @worker.run
    end

    private

    class WorkerPartial
      include Worker
    end

    def create(retry_check_count = 1)
      @queue = flexmock('queue')
      @queue.should_ignore_missing
      @worker = flexmock WorkerPartial.new(@queue, retry_check_count)
      @worker.worker_retry_check_count = retry_check_count
      @worker.worker_queue = @queue
    end

  end
end
