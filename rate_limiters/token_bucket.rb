require 'minitest/autorun'
require 'async'

# Used by Amazon and Stripe
class TokenBucket
  TOTAL_TOKENS = 4

  attr_reader :tokens

  def initialize
    @tokens = TOTAL_TOKENS
  end

  def handle(_)
    if @tokens > 0
      @tokens -= 1
      true
    else
      false
    end
  end

  def refill!
    @tokens += 1
    @tokens = TOTAL_TOKENS if @tokens > TOTAL_TOKENS
  end

  def enough_tokens?
    @tokens > 0
  end
end

class TokenBucketTest < Minitest::Test
  def test_it_handles_requests_if_there_are_enough_tokens
    bucket = TokenBucket.new
    assert bucket.enough_tokens?
    4.times { assert bucket.handle(:request) }
    refute bucket.handle(:request)
  end

  def test_it_refills_tokens_every_10_milliseconds
    bucket = TokenBucket.new
    Async do
      Async do
        1.upto(2) do
          sleep 0.01
          bucket.refill!
        end
      end

      4.times { bucket.handle(:request) }
      refute bucket.handle(:request)
      sleep 0.01
      assert bucket.handle(:request)
      refute bucket.handle(:request)
    end
  end
end
