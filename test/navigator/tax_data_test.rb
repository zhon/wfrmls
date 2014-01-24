require 'test_helper'

require 'street_address_ext'

require 'wfrmls/navigator/tax_data'

include Wfrmls::Navigator
describe TaxData do

  before do
    @browser = stub('browser')
    @address = StreetAddressExt.parse '123 N 456 E, Bountiful'
    @nav = TaxData.new @browser
  end

  describe 'go' do

    it 'with one result calls click_link' do
      link = stub('link')
      stub(@nav).hit_url
      stub(@nav).reduce_rows { [ link ] }
      mock(@nav).click_link link
      @nav.go(@address)
    end

    describe 'raises' do

      it 'with empty results' do
        stub(@nav).hit_url
        stub(@nav).reduce_rows { [] }
        e = assert_raises Error do
          @nav.go(@address)
        end
        e.message.must_equal "'123 N 456 E, Bountiful' not found in tax data"
      end

      it 'with too many results' do
        link = stub('link')
        stub(link).cell { stub!.text { 'link' } }
        stub(@nav).hit_url
        stub(@nav).reduce_rows { [link, link] }
        e = assert_raises Error do
          @nav.go(@address)
        end
        e.message.must_equal "Possible matches:\nlink\nlink"
      end

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

