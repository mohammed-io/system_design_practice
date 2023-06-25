require 'minitest/autorun'
require 'async'

# Used by Shopify

class LeakingBucket
  QUEUE_SIZE = 4

  attr_reader :queue

  def initialize
    @queue = []
  end

  def handle(req)
    if @queue.size < QUEUE_SIZE
      @queue << req
      true
    else
      false
    end
  end

  def process_next_request!
    @queue.shift&.process
  end
end

class Request
  def process
    @processed = true
  end

  def processed?
    @processed
  end
end

class LeakingBucketTest < Minitest::Test
  def test_it_handles_requests_if_there_is_space_in_the_queue
    bucket = LeakingBucket.new
    assert bucket.handle(Request.new)
    assert bucket.handle(Request.new)
    assert bucket.handle(Request.new)
    assert bucket.handle(Request.new)
    refute bucket.handle(Request.new)
  end

  def test_it_processes_requests_in_the_queue
    bucket = LeakingBucket.new
    req_1 = Request.new
    req_2 = Request.new
    bucket.handle(req_1)
    3.times { bucket.handle(Request.new) }
    # Not going into the queue
    refute bucket.handle(req_2)

    4.times { bucket.process_next_request! }
    assert req_1.processed?
    refute req_2.processed? # Never made it to te queue
  end

  def test_it_processes_requests_in_the_queue_in_order_every_10ms
    Async do
      bucket = LeakingBucket.new

      Async do
        1.upto(10) do
          sleep 0.01
          bucket.process_next_request!
        end
      end

      req_1 = Request.new
      req_2 = Request.new
      bucket.handle(req_1)
      3.times { bucket.handle(Request.new) }

      refute req_1.processed?
      refute bucket.handle(req_2)

      assert_equal(4, bucket.queue.size)

      sleep 0.01
      # Processes the first request in the queue
      assert_equal(3, bucket.queue.size)
      assert req_1.processed?
      refute req_2.processed? # Never made it

      # Processes 2 more requests
      sleep 0.02
      assert_equal(2, bucket.queue.size)
      assert bucket.handle(req_2)
      assert_equal(3, bucket.queue.size)
      refute req_2.processed?

      sleep 0.02
      assert_equal(1, bucket.queue.size)
      refute req_2.processed?

      # The req_2 is the last one in the queue
      sleep 0.01
      assert_equal(0, bucket.queue.size)
      assert req_2.processed?
    end
  end
end
