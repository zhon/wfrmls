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

  it '' do
    skip
    addr = StreetAddressExt.parse '123 N 456 E, Bountiful'
    page = 'page'
    browser = stub('browser').page { page }
    stub(browser).table { stub('table').rows { [] }}
    #mock(browser).goto("http://www.utahrealestate.com/taxdata/index?county[]=2&searchtype=house&searchbox=123") {
      #page
    #}
    nav = Navigator.new browser
    mock(nav).goto("http://www.utahrealestate.com/taxdata/index?county[]=2&searchtype=house&searchbox=123")
    nav.go(addr).must_equal page
  end

  describe 'click_correct_link' do

    it 'with no links prints error message' do
      mock(@nav).puts "'#@address' not found in tax data"
      @nav.click_correct_link [], @address
    end

    it 'with one link will click the link' do
      link = 'row item'
      mock(@nav).click_link(link)
      @nav.click_correct_link [ link ], @address
    end

  end

  describe 'reduce_rows' do

    it 'with empty rows returns [false, []]' do
      @nav.reduce_rows([], stub('address'), [:by_street]).must_equal [false, []]
    end

    it 'with single item returns item' do
      item = mock('item')
      mock(@nav).reduce_by.with_any_args { [ item ] }
      @nav.reduce_rows([item], stub('address'), [:by_street]).must_equal [true, item]
    end

    it 'with multiple items and mutiple methods will call itself' do
      item1 = mock('item1')
      item2 = mock('item2')
      mock(@nav).reduce_by.with_any_args { [ item1, item2 ] }
      mock(@nav).reduce_by.with_any_args { [ item2 ] }
      @nav.reduce_rows([item1, item2], stub('address'), [:by_street, :by_street ]).must_equal [true, item2]
    end

  end


end

#class ThisTest < Minitest

  #def test_this
    #flunk
  #end

#end

