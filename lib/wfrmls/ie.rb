require 'watir'
require 'street_address'


module Wfrmls
  class IE

    def initialize(ie, username, password)
      @username = username
      @password = password
      @ie = ie
    end

    def login
      @ie.goto 'http://www.utahrealestate.com/auth/login/login_redirect//force_redirect/1'
      begin
        @ie.text_field(:id, 'login').set @username
        @ie.text_field(:id, 'pass').set @password
        @ie.button(:id, 'submit_button').click

        sleep_until { @ie.url == 'http://www.utahrealestate.com/' }
      rescue
        # we are already logged in
      end
    end

    def residential_full_search
      @ie.radio(:id, 'historical_data_yes').set
    end

    def lookup_address(addr)
      goto 'http://www.utahrealestate.com/search/form/type/1/name/full?advanced_search=1'
      residential_full_search

      status

      @ie.text_field(:id, 'street').set addr.street
      @ie.text_field(:id, 'housenum').set addr.number

      city(addr.city)

      result_count = @ie.span(:id, 'action_search_count').text.to_i

      if result_count > 0

        @ie.button(:id, 'SEARCH_button').click
        begin
          sleep 1
          @ie.checkbox(:id, 'ListingController').click
        rescue
          retry
        end

        @ie.select_list(:id, 'report-selector').set('Full Report')
      else
        show_tax_data(addr)
      end
    end

    def status
      settings = ['Active', 'Sold', 'Under Contract', 'Expired']
      @ie.div(:id, 'status1Container_clear_button').click
      tf = @ie.text_field(:id, 'status1Container_input')
      settings.each do |item|
        tf.set(item)
      end
    end

    def city(name)
      # clear the city field
      if not @ie.hidden(:id, 'city').value.empty?
        @ie.div(:id, 'city1Container_clear_button').click
        sleep_until { @ie.hidden(:id, 'city').value.empty? }
        @ie.focus
      end

      @ie.text_field(:id, 'city1Container_input').set( name + ',' )
      @ie.focus

      sleep_until { @ie.dd(:id, 'left_search_criteria').text.include? 'City is' }
    end

    def sleep_until &block
      count = 0
      until yield block
        sleep 1
        count += 1
        exit if count > 10
      end
    end

    def show_tax_data(addr)
      goto "http://www.utahrealestate.com/taxdata/index?county%5B%5D=2&county%5B%5D=8&searchtype=house&searchbox=#{addr.number}"

      street_regx = Regexp.new(addr.street, Regexp::IGNORECASE)
      @ie.table(:class, 'tax-data').rows.each do |row|
        if street_regx =~ row.text
          row.cells[2].links[1].click
          break
        end
      end
    end

    def goto(url)
      @ie.goto url
      if @ie.link(:id, 'login_anchor').exists?
        login
        @ie.goto url
      end
    end
  end
end
