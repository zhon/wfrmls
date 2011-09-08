require 'wfrmls/tax_data_search'

require 'test/unit'
require 'flexmock/test_unit'

module Wfrmls
  class TaxdataTest < Test::Unit::TestCase

    def test_show_tax_data_with_nothing_found
      ie = flexmock('ie')
      addr = flexmock('addr') do |item|
        item.should_receive(:number).returns('1')
        item.should_receive(:to_s).and_return('address')
      end
      search = Wfrmls::TaxDataSearch.new(ie)
      flexmock(search) do |m|
        m.should_receive(:goto)
        m.should_receive(:find_tax_data_rows_by_house_and_street).
          and_return([])
        m.should_receive(:puts).with('address not found in tax data')
      end
      search.show_tax_data(addr)
    end

  end
end
