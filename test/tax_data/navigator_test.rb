require 'test_helper'

require 'street_address_ext'

require 'wfrmls/tax_data/navigator'

include Wfrmls::TaxData
describe Navigator do

  before do
    @browser = stub('browser')
    @address = StreetAddressExt.parse '123 N 456 E, Bountiful'
    @nav = Navigator.new @browser
  end

  describe 'go' do

    it 'with no results prints a message' do
      addr = StreetAddressExt.parse '123 N 456 E, Bountiful'
      page = 'page'
      browser = stub('browser').page { page }
      stub(browser).table { stub('table').rows { [] }}
      nav = Navigator.new browser
      mock(nav).goto("http://www.utahrealestate.com/taxdata/index?county[]=2&searchtype=house&searchbox=123")
      mock(nav).puts "'123 N 456 E, Bountiful' not found in tax data"
      nav.go(addr)
    end

  end

  describe 'reduce_rows' do

    it 'with empty rows returns []' do
      @nav.reduce_rows([], stub('address'), [:by_street]).must_equal []
    end

    it 'with single item returns item' do
      item = stub('item')
      stub(@nav).reduce_by.with_any_args { [ item ] }
      @nav.reduce_rows([item], stub('address'), [:by_street]).must_equal item
    end

    it 'with multiple items and mutiple methods will call itself' do
      item1 = stub('item1')
      item2 = stub('item2')
      mock(@nav).reduce_by.with_any_args { [ item1, item2 ] }
      mock(@nav).reduce_by.with_any_args { [ item2 ] }
      @nav.reduce_rows([item1, item2], stub('address'), [:by_street, :by_street ]).must_equal item2
    end

  end


end

#class ThisTest < Minitest

  #def test_this
    #flunk
  #end

#end

