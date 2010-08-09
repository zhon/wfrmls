require 'wfrmls/authenticator'

require 'test/unit'
require 'flexmock/test_unit'

class ManualAuthenticatorTest < Test::Unit::TestCase
  def test_goto_login_page
    mock_ie = flexmock('watir')
    auth = flexmock ManualAuthenticator.new(mock_ie)
    mock_ie.should_receive(:url).and_return('')
    mock_ie.should_receive(:goto).once

    auth.should_receive(:logged_in?).and_return(true)
    auth.login
  end

  def test_do_not_goto_login_page_if_already_on_utahrealestate_site
    mock_ie = flexmock('watir')
    auth = flexmock ManualAuthenticator.new(mock_ie)
    mock_ie.should_receive(:url).and_return('utahrealestate.com')
    mock_ie.should_receive(:goto).never

    auth.should_receive(:logged_in?).and_return(true)
    auth.should_receive(:sleep_until).never
    auth.login
  end

  def test_already_logged_in_shouldnt_log_in_again
    mock_ie = flexmock('watir')
    auth = flexmock ManualAuthenticator.new(mock_ie)
    mock_ie.should_receive(:url).and_return('utahrealestate.com')
    auth.should_receive(:logged_in?).and_return(true)

    auth.should_receive(:sleep_until)

    auth.login
  end

  def test_not_logging_in_raises_exception
    mock_ie = flexmock('watir')
    auth = flexmock ManualAuthenticator.new(mock_ie)
    mock_ie.should_receive(:url).and_return('utahrealestate.com')

    auth.should_receive(:sleep_until)
    auth.should_receive(:logged_in?).and_return(false)

    assert_raise RuntimeError do
      auth.login
    end
  end

  def xxxtest_this
    ie = Watir::Browser.new

    auth = ManualAuthenticator.new(ie)
    auth.login
  end

end
