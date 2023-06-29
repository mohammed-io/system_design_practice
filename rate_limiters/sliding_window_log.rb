require 'minitest/autorun'
require 'async'

class SlidingWindowLog
  attr_reader :log

  MAX_REQUESTS_PER_WINDOW = 2

  def initialize
    @log = []
  end

  def handle(_)
    if @log.empty?
      @log << current_window
      true
    elsif @log.select { _1 == current_window }.size < MAX_REQUESTS_PER_WINDOW
      @log = log.last(2)
      @log << current_window
      true
    else
      false
    end
  end

  def current_window
    Time.now.to_i
  end
end

class SlidingWindowLogTest < Minitest::Test
  def test_it_handles_requests_if_there_is_space_in_the_window
    log = SlidingWindowLog.new
    assert log.handle(:request)
    assert log.handle(:request)
    refute log.handle(:request)
  end

  def test_it_handles_request_after_the_time_window_passed
    Async do
      log = SlidingWindowLog.new
      assert log.handle(:request)
      assert log.handle(:request)
      refute log.handle(:request)
      sleep 1
      assert log.handle(:request)
      assert log.handle(:request)
      refute log.handle(:request)
    end
  end
end
