require 'minitest/autorun'
require 'async'

class FakeTime
  def self.timestamp
    @timestamp ||= 0
  end

  def self.advance(seconds = 1)
    @timestamp = timestamp + seconds
  end
end

class SlidingWindowLog
  attr_reader :log

  MAX_REQUESTS_PER_WINDOW = 3
  WINDOW_SIZE_IN_SECONDS = 10

  def initialize
    @log = []
  end

  def handle(_)
    @log << FakeTime.timestamp

    @log.reject! { |timestamp| current_window - timestamp >= WINDOW_SIZE_IN_SECONDS }

    if @log.size <= MAX_REQUESTS_PER_WINDOW
      true
    else
      false
    end
  end

  def current_window
    (FakeTime.timestamp / WINDOW_SIZE_IN_SECONDS) * WINDOW_SIZE_IN_SECONDS + 1
  end
end

class SlidingWindowLogTest < Minitest::Test
  def test_it_handles_requests_if_there_is_space_in_the_window
    log = SlidingWindowLog.new
    assert log.handle(:request)
    assert log.handle(:request)
    assert log.handle(:request)
    refute log.handle(:request)
  end

  def test_it_handles_request_after_the_time_window_passed
    log = SlidingWindowLog.new
    assert log.handle(:request)
    FakeTime.advance(5)
    assert log.handle(:request)
    FakeTime.advance(2)
    assert log.handle(:request)
    refute log.handle(:request)

    FakeTime.advance(12)
    refute log.handle(:request)

    FakeTime.advance(1)
    assert log.handle(:request)
    FakeTime.advance(9) # last second in the 2nd window
    assert log.handle(:request)
    refute log.handle(:request) # Burst prevented.

    # After long time, i.e. the previous window has passed;
    FakeTime.advance(100)
    assert log.handle(:request)
    assert log.handle(:request)
    assert log.handle(:request)
    refute log.handle(:request)
  end
end
