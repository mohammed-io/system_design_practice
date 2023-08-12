class FakeTime
  def self.timestamp
    @timestamp ||= 0
  end

  def self.advance(seconds = 1)
    @timestamp = timestamp + seconds
  end
end
