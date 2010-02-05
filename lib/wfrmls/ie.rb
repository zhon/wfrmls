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
      address(addr)

      result_count = @ie.span(:id, 'action_search_count').text.to_i

      if result_count > 0
        show_full_listings
      else
        show_tax_data(addr)
      end
    end

    def show_full_listings
      @ie.button(:id, 'SEARCH_button').click
      sleep_until { @ie.checkbox(:id, 'ListingController').exists? }
      @ie.checkbox(:id, 'ListingController').click
      @ie.select_list(:id, 'report-selector').set('Full Report')
    end

    def comp(addr, house_details = collect_property_details(addr))
      # TODO remove the sleeps
      goto 'http://www.utahrealestate.com/search/form/type/1/name/full?advanced_search=1'

      @ie.button(:id, 'CLEAR_button').click
      sleep 3

      goto 'http://www.utahrealestate.com/search/form/type/1/name/full?advanced_search=1'

      residential_full_search
      status
      city(addr.city)

      @ie.text_field(:id, 'days_back_status').set('120')

      
      @ie.text_field(:name, 'tot_sqf1').set((house_details[:house_size] - 200).to_s)
      @ie.text_field(:name, 'tot_sqf2').set((house_details[:house_size] + 200).to_s)

      @ie.text_field(:name, 'yearblt1').set((house_details[:year_built] - 6).to_s)
      @ie.text_field(:name, 'yearblt2').set((house_details[:year_built] + 6).to_s)

      sleep 3

      show_full_listings
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

    def address(addr)
      @ie.text_field(:id, 'street').set addr.street
      @ie.text_field(:id, 'housenum').set addr.number
      city(addr.city)
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

      rows = find_tax_data_rows_by_house_and_street(addr)

      case rows.size
      when 0
        puts "#{addr} not found in tax data"
      when 1
        click_link rows[0]
      else
        puts 'Possible matches:'
        rows.each do |item|
          puts item.cell(:class, 'last-col').text
        end
      end
    end

    def click_link(item)
      item.link(:index, 1).click
    end

    def find_tax_data_rows_by_house_and_street(addr)
      rows = []
      @ie.table(:class, 'tax-data').rows.to_a[1..-1].each do |row|
        if row.cell(:class, 'last-col').text.include? addr.street.upcase
          rows << row
        end
      end
      rows 
    end

    def goto(url)
      @ie.goto url
      if @ie.link(:id, 'login_anchor').exists?
        login
        @ie.goto url
      end
    end

    def collect_property_details(addr)
      show_tax_data(addr) unless @ie.url.include? 'taxdata/details' 

      doc = @ie.xmlparser_document_object

      details = {}

      doc.search('tr/th').each do |item|
        case nbsp2sp(item.text)
        when /NAME:/
          details[:owner] = item.parent.search('td').text
        when /ADDRESS:/
          details[:address] = item.parent.search('td').text.strip
        when /PARCEL SPECIFIC INFO:/
          nbsp2sp(item.parent.search('td').text) =~ /Total Acres: ([.0-9]+)/
          details[:lot_size] = $1
        when /VALUATION SPECIFIC INFO:/
          nbsp2sp(item.parent.search('td').text) =~ /Final Value: (\$[0-9,]+)/
          details[:tax_value] = $1
        when /GENERAL INFO:/
          nbsp2sp(item.parent.search('td').text) =~ /Yr Built: ([0-9]+)/
          details[:year_built] = $1.to_i
        when /AREA INFO:/
          house_size = 0
          data = nbsp2sp(item.parent.search('td').text)
          data =~ /Main Floor Area: ([,0-9]+)/
          house_size += $1.sub(',','').to_i if $1
          data =~ /Basement Area: ([,0-9]+)/
          house_size += $1.sub(',','').to_i if $1
          data =~ /Upper Floor Area: ([,0-9]+)/
          house_size += $1.sub(',','').to_i if $1
          details[:house_size] = house_size
        when /EXTERIOR:/
          details[:exterior] ||= {}
          data = nbsp2sp(item.parent.search('td').text)
          data =~ /Ext. Wall Type: (\w+)/
          details[:exterior][:wall] = $1
          data =~ /Masonry Trim: (\w+)/
          details[:exterior][:masonry_trim] = $1
        when /CARPORT & GARAGE INFO:/
          data = nbsp2sp(item.parent.search('td').text)
          data =~ /(.*): ([0-9]+)/
          details[:parking] = nil
          if $1
            details[:parking] = {}
            details[:parking][$1] = $2.to_i
          end
        end
      end

      details
    end

    def nbsp2sp(s)
      s.gsub("\xC2\xA0", ' ')
    end
  end
end
