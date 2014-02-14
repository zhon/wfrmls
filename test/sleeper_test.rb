require 'test_helper'

require 'wfrmls/sleeper'

include Sleeper
describe Sleeper do

  it 'doesnt sleep if result is true' do
    mock(self).sleep.never
    sleep_until { true }
  end

  it 'sleeps default times (10)' do
    mock(self).sleep(1).times(10)
    sleep_until { false }
  end

  it 'sleeps once' do
    mock(self).sleep(1)
    sleep_until(1) { false }
  end

end
