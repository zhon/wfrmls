require 'wfrmls/sleeper'
require 'wfrmls/authenticator'
require 'wfrmls/worker'
require 'thread'

module Wfrmls
  class ResidentialSearch
    include Sleeper
    include AutomaticAuthenticator

    def initialize(ie, queue=Queue.new)
      @ie = ie
      @@worker_queue = queue
    end

    def comp(addr, house_details)
      goto_search_page
      historical_data
      status
      city(addr.city)
      short_sale(false)
      house_size(house_details)
      days_back
      year_built = house_details[:year_built]
      year_built_range(year_built - 6, year_built + 6)
      execute_commands
      show_full_listings
      execute_commands
    end

    def lookup_opposition(addr)
      find_address(addr)
      show_listings
    end

    def find_address(addr)
      goto_search_page
      historical_data
      status
      address(addr)
      execute_commands
    end

    def goto_search_page
      it -> {
        url = 'http://www.utahrealestate.com/search/form/type/1/name/full?advanced_search=1'
        goto url
        clear_search
        goto url
      }
    end

    def results_availible?
      execute_commands
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
      it -> { @ie.radio(:id, 'historical_data_yes').set }
    end

    def status(args = Settings.status)
      it -> {
        set_items args,'status1Container_input','status1Container_bot_close'
      }, -> {
        search_criteria_set? 'Status is'
      }
    end

    def property_type(args)
      it -> {
        set_items args,
          'proptype1Container_input',
          'proptype1Container_bot_close'
      }, -> {
        search_criteria_set? 'Property Type'
      }
    end

    def address(addr)
      house(addr.number)
      street(addr.street)
      city(addr.city)
    end

    def city(name)
      it -> {
        set_items name,'city1Container_input','city1Container_bot_close'
      }, -> {
        search_criteria_set? 'City is'
      }
    end

    def street(street)
      it -> {
        @ie.text_field(:id, 'street').set street
      } , -> {
        search_criteria_set? 'Street'
      }
    end

    def house(house)
      it -> {
        @ie.text_field(:id, 'housenum').set house
      } , -> {
        search_criteria_set? 'House Number is'
      }
    end

    def county(args)
      it -> {
        set_items args,
          'county_code1Container_input',
          'county_code1Container_bot_close'
      }, -> {
        search_criteria_set? 'County is'
      }
    end

    def short_sale(includes=true)
      it -> {
        if includes
          @ie.radio(:id, 'o_shortsale_4').click
        else
          @ie.radio(:id, 'o_shortsale_8').click
        end
        @ie.checkbox(:id, 'shortsale_2').click
        @ie.checkbox(:id, 'shortsale_4').click
      }
    end

    def year_built_range(early, later)
      it -> {
        @ie.text_field(:name,'yearblt1').set(early.to_s) if early
        @ie.text_field(:name,'yearblt2').set(later.to_s) if later
      }
    end

    def house_size(house_details)
      it -> {
        house_size = house_details[:house_size]
        @ie.text_field(:name,'tot_sqf1').set((house_size-200).to_s)
        @ie.text_field(:name,'tot_sqf2').set((house_size+200).to_s)
      } , -> {
        search_criteria_set? 'Total Square Feet'
      }
    end

    def days_back
      it -> {
        @ie.text_field(:id, 'days_back_status').set(Settings.days_back.to_s)
      } , -> {
        search_criteria_set? 'Number of Days Back'
      }
    end

    def owner_type_not_owner_agent
      it -> {
        @ie.radio(:id, 'o_owner_type_2').click
        @ie.checkbox(:id, 'owner_type_4').click
      }
    end

    def execute_commands
      while not @@worker_queue.empty?
        worker = @@worker_queue.deq
        worker.run
      end
    end

    private

    def clear_search
      @ie.button(:id,'CLEAR_button').click
      sleep_until(3) { @ie.dd(:id, 'left_search_criteria').text !~ /City/ }
    end

    def set_items(items, input_id, close_button_id)
      items = Array(items)
      tf = @ie.text_field(:id, input_id)
      tf.set(items.join ',')
      @ie.link(:id, close_button_id).click
    end

    def search_criteria_set?(text)
      result = sleep_until(3) {
        @ie.dd(:id,'left_search_criteria').text.include? text
      }
      result
    end

    def it work, check=nil
      worker = self.clone
      class << worker
        include Worker
      end
      worker.singleton_class.send :define_method, :work, work
      if check
        worker.singleton_class.send(:define_method, :check_work, check)
      else
        worker.worker_retry_check_count = 0
      end
      worker.worker_queue = @@worker_queue
      @@worker_queue.enq worker
    end

  end
end
