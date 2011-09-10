module Sleeper
  def sleep_until max=10, &block
    count = 0
    until (result = yield block)
      sleep 1
      count += 1
      return result if count > max
    end
    result
  end
end
