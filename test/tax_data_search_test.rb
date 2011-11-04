require 'wfrmls/tax_data_search'

require 'test/unit'
require 'flexmock/test_unit'

module Wfrmls
  class TaxdataTest < Test::Unit::TestCase

    def create_addr
      addr = flexmock('addr') do |item|
        item.should_receive(:number).returns('1')
        item.should_receive(:to_s).and_return('address')
        item.should_ignore_missing
      end
    end

    def create_search(tax_data_rows)
      ie = flexmock('ie')
      search = Wfrmls::TaxDataSearch.new(ie)
      flexmock(search) do |m|
        m.should_receive(:goto)
        m.should_receive(:find_tax_data_rows_by_house_and_street).
          and_return(tax_data_rows)
      end
      search
    end

    def test_show_tax_data_with_nothing_found
      search = create_search([])
      search.should_receive(:puts).with('address not found in tax data')
      search.show_tax_data(create_addr)
    end

    def test_show_tax_data_when_one_item_is_returned
      search = create_search(['row item'])
      search.should_receive(:click_link).once
      search.show_tax_data(create_addr)
    end

    def test_show_tax_data_with_two_items_returned
      skip
      search = create_search(['row item', 'another item'])
      search.should_receive(:click_link).once
      search.show_tax_data(create_addr)
    end

  end
end
