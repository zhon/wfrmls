require 'wfrmls/sleeper'
require 'wfrmls/authenticator'

module Wfrmls
  class ResidentialSearch # < Wfrmls::IE
    include Sleeper
    include AutomaticAuthenticator

    def initialize(ie)
      @ie = ie
    end

    def comp(addr, house_details)
      goto_search_page
      historical_data
      status
      city(addr.city)
      short_sale(false)
      house_size(house_details)

      days_back

      sleep_until(3) {
        @ie.dd(:id,'left_search_criteria').text.include? 'Year Built at most'
      }

      show_full_listings
    end

    def lookup_opposition(addr)
      find_address_on_search_page(addr)
      show_listings
    end

    def find_address_on_search_page(addr)
      goto_search_page
      historical_data
      status
      address(addr)
    end

    def goto_search_page
      url = 'http://www.utahrealestate.com/search/form/type/1/name/full?advanced_search=1'
      goto url
      clear_search
      goto url
    end

    def results_availible?
      result_count = @ie.span(:id, 'action_search_count').text.to_i > 0
    end

    def show_listings
      return false unless results_availible?
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

    def historical_data
      @ie.radio(:id, 'historical_data_yes').set
    end

    def status(args = Settings.status)
      set_items 'status1Container_clear_button', 'status1Container_input', args
    end

    def address(addr)
      @ie.text_field(:id, 'housenum').set addr.number
      street(addr.street)
      city(addr.city)
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

      sleep_until {@ie.dd(:id, 'left_search_criteria').text.include? 'City is'}
    end

    def street(street)
      @ie.text_field(:id, 'street').set street
      sleep_until { @ie.dd(:id, 'left_search_criteria').text.include? 'Street' }
    end

    def county(args)
      set_items 'county_code1Container_clear_button',
        'county_code1Container_input', args
    end

    private

    def set_items(clear_button, input_field, args)
      args = Array(args)
      @ie.div(:id, clear_button).click
      tf = @ie.text_field(:id, input_field)
      args.each do |item|
        tf.set(item)
      end
    end

    def clear_search
      @ie.button(:id,'CLEAR_button').click
      sleep_until(3) { @ie.dd(:id, 'left_search_criteria').text !~ /City/ }
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

    def house_size(house_details)
      @ie.text_field(:name,'tot_sqf1').set((house_details[:house_size]-200).to_s)
      @ie.text_field(:name,'tot_sqf2').set((house_details[:house_size]+200).to_s)
    end

    def days_back
      @ie.text_field(:id, 'days_back_status').set(Settings.days_back.to_s)
    end

  end
end
