require 'wfrmls/sleeper'
require 'configliere'

module Wfrmls
  module Authenticator
    def initialize(ie)
      @ie = ie
    end

    def goto(url)
      @ie.goto url
      unless logged_in?
        login
        @ie.goto url
      end
    end

    def logged_in?
      return ! @ie.div(:id, 'login-div').exists?
    end
  end

  module ManualAuthenticator
    include Authenticator
    include Sleeper

    def login
      login_url = 'http://www.utahrealestate.com/auth/login/login_redirect//force_redirect/1'

      @ie.goto login_url unless @ie.url.include? 'utahrealestate.com'
      return if logged_in?

      sleep_until(30) { @ie.url == 'http://www.utahrealestate.com/' }
      raise "Please login" unless logged_in?
    end
  end

  module AutomaticAuthenticator
    include Authenticator
    include Sleeper

    def initialize(ie, username, password)
      super(ie)
      @username = username
      @password = password
    end

    def login
      @ie.goto 'http://www.utahrealestate.com/auth/login/login_redirect//force_redirect/1'
      begin
        @ie.text_field(:id, 'login').set Settings[:username]
        @ie.text_field(:id, 'pass').set Settings[:password]
        @ie.button(:id, 'submit_button').click

        sleep_until { @ie.url == 'http://www.utahrealestate.com/' }
      rescue
        # we are already logged in
      end
    end
  end
end
