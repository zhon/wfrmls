module Sleeper
  def sleep_until max=10, &block
    count = 0
    until count >= max or (result = yield block)
      sleep 1
      count += 1
    end
    result
  end
end
