module Sleeper
  def sleep_until max=10, &block
    count = 0
    until yield block
      sleep 1
      count += 1
      return if count > max
    end
  end
end
