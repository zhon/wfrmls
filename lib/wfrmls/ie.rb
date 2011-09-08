# encoding: UTF-8

require 'street_address'
require 'wfrmls/sleeper'
require 'wfrmls/authenticator'
require 'wfrmls/citycountymap'

require 'configliere'

Settings.use :define
Settings.define :days_back, description: "Compare NUMBER of days back.",
  type: Integer, default: 120

# TODO house_size_difference
# surrounding years
# include short sale?
# status 'Active', 'Sold', 'Under Contract', 'Expired'


module Wfrmls
  class IE
    include Sleeper

    def initialize(ie, auth)
      @ie = ie
      @auth = auth
    end

    def lookup_address(addr)
      find_address_on_search_page(addr)

      if search_results_availible?
        show_full_listings
      else
        show_tax_data(addr)
      end
    end

    def lookup_opposition(addr)
      find_address_on_search_page(addr)
      show_listings
    end

    def comp(addr, house_details = collect_property_details(addr))
      goto_search_page
      historical_data
      status
      city(addr.city)
      short_sale(false)

      @ie.text_field(:id, 'days_back_status').set(Settings.days_back.to_s)


      @ie.text_field(:name,'tot_sqf1').set((house_details[:house_size]-200).to_s)
      @ie.text_field(:name,'tot_sqf2').set((house_details[:house_size]+200).to_s)

      @ie.text_field(:name,'yearblt1').set((house_details[:year_built]-6).to_s)
      @ie.text_field(:name,'yearblt2').set((house_details[:year_built]+6).to_s)

      sleep_until(3) {
        @ie.dd(:id,'left_search_criteria').text.include? 'Year Built at most'
      }

      show_full_listings
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
          data = nbsp2sp(item.parent.search('td').text)
          data =~ /Yr Built: ([0-9]+)/
          details[:year_built] = $1.to_i
          data =~ /Bldg Style: (.*?) \xE2\x80\xA2/
          details[:type] = $1.strip
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
        when /ROOM INFO:/
          details[:rooms] ||= {}
          data = nbsp2sp(item.parent.search('td').text)
          data =~ /Total Rooms: (\d+)/
          details[:rooms][:total] = $1.to_i
          data =~ /Bedrooms: (\d+)/
          details[:rooms][:bedrooms] = $1.to_i
          data =~ /Full Baths: (\d+)/
          br = $1.to_i
          data =~ /1\/2 Baths: (\d+)/
          br += $1.to_i
          data =~ /3\/4 Baths: (\d+)/
          br += $1.to_i
          details[:rooms][:baths] = br
        when /CARPORT & GARAGE INFO:/
          data = nbsp2sp(item.parent.search('td').text)
          details[:parking] = nil
          data.scan(/([\w -]*): ([0-9]+)/) do |x,y|
            details[:parking] ||= {}
            details[:parking][x.strip] = y.to_i
          end
        end
      end

      details
    end

    def show_tax_data(addr)

      rows = find_tax_data_rows_by_house_and_street(addr)

      case rows.size
      when 0
        puts "#{addr} not found in tax data"
      when 1
        click_link rows[0]
      else
        regex = /\b#{addr.prefix}\b.*\b#{addr.suffix}/
        rows = rows.inject([]) do |c, item|
          c << item if regex.match item.cell(:class, 'last-col').text
          c
        end
        case rows.size
        when 0
          puts "#{addr} not found with #{regex}"
        when 1
          click_link rows[0]
        else
          puts 'Possible matches:'
          rows.each do |item|
            puts item.cell(:class, 'last-col').text
          end
        end
      end
    end

private
    def historical_data
      @ie.radio(:id, 'historical_data_yes').set
    end

    def find_address_on_search_page(addr)
      goto_search_page
      historical_data
      status
      address(addr)
    end

    def short_sale(includes=true)
      if includes
        @ie.radio(:id, 'o_shortsale_4').click
      else
        @ie.radio(:id, 'o_shortsale_8').click
      end
      @ie.checkbox(:id, 'shortsale_2').click
      @ie.checkbox(:id, 'shortsale_4').click
    end

    def search_results_availible?
      result_count = @ie.span(:id, 'action_search_count').text.to_i > 0
    end

    def show_listings
      return false unless search_results_availible?
      @ie.button(:id, 'SEARCH_button').click
      sleep_until { @ie.checkbox(:id, 'ListingController').exists? }
      true
    end

    def show_full_listings
      show_listings || return
      @ie.checkbox(:id, 'ListingController').click
      sleep 1
      @ie.select_list(:id, 'report-selector').set('Full Report')
    end

    def goto_search_page
      url = 'http://www.utahrealestate.com/search/form/type/1/name/full?advanced_search=1'
      goto url
      clear_search
      goto url
    end

    def clear_search
      @ie.button(:id,'CLEAR_button').click
      sleep_until(3) { @ie.dd(:id, 'left_search_criteria').text !~ /City/ }
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

    def street(street)
      @ie.text_field(:id, 'street').set street
      sleep_until { @ie.dd(:id, 'left_search_criteria').text.include? 'Street' }
    end

    def address(addr)
      @ie.text_field(:id, 'housenum').set addr.number
      street(addr.street)
      city(addr.city)
    end

    def click_link(item)
      item.link(:index, 1).click
    end

    def select_county(addr)
      goto "http://www.utahrealestate.com/taxdata/index?searchtype=house&searchbox=#{addr.number}"

      # uncheck davis county (it is checked by default)
      @ie.checkbox(:title, 'Davis').click
      @ie.checkbox(:title, CityToCounty[addr.city]).click
      @ie.button(:id, 'SEARCH_button').click
    end

    def find_tax_data_rows_by_house_and_street(addr)
      select_county(addr)

      reg = Regexp.new("\\b#{addr.street}\\b", Regexp::IGNORECASE)
      rows = []
      @ie.table(:class, 'tax-data').rows.to_a[1..-1].each do |row|
        if reg.match row.cell(:class, 'last-col').text
          rows << row
        end
      end
      rows
    end

    def goto(url)
      @ie.goto url
      unless @auth.logged_in?
        @auth.login
        @ie.goto url
      end
    end

    def nbsp2sp(s)
      s.gsub("\xC2\xA0", ' ')
    end
  end
end
