require 'test_helper'

require 'wfrmls/tax_data_search'
require 'wfrmls/navigator/tax_data'

include Wfrmls
describe TaxDataSearch do

  describe 'collect_property_details' do

    before do
      @browser = stub!
      @address = stub!
    end

    describe 'fails' do

      it 'prints error' do
        error_msg = "error msg"
        stub(Navigator::TaxData).new do
          stub!.go { raise Navigator::Error, error_msg }
        end
        search = TaxDataSearch.new @browser
        mock(search).puts(error_msg)
        search.collect_property_details @address
      end

    end

  end

end
