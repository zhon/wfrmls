require 'sleeper'

class Authenticator
  def initialize(ie)
    @ie = ie
  end

  def logged_in?
    return ! @ie.div(:id, 'login-div').exists?
  end
end

class ManualAuthenticator < Authenticator
  include Sleeper

  def login
    login_url = 'http://www.utahrealestate.com/auth/login/login_redirect//force_redirect/1'

    @ie.goto login_url unless @ie.url.include? 'utahrealestate.com'
    return if logged_in?

    sleep_until(30) { @ie.url == 'http://www.utahrealestate.com/' }
    raise "Please login" unless logged_in?
  end
end

class AutomaticAuthenticator < Authenticator
  include Sleeper

  def initialize(ie, username, password)
    super(ie)
    @username = username
    @password = password
  end

  def login
    @ie.goto 'http://www.utahrealestate.com/auth/login/login_redirect//force_redirect/1'
    sleep 5
    puts @ie.html
    begin
      @ie.text_field(:id, 'login').set @username
      @ie.text_field(:id, 'pass').set @password
      @ie.button(:id, 'submit_button').click

      sleep_until { @ie.url == 'http://www.utahrealestate.com/' }
    rescue
      # we are already logged in
    end
  end
end
