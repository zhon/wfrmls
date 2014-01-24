require 'test_helper'

require 'wfrmls/tax_data_search'

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
        stub(TaxData::Navigator).new do
          stub!.go { raise TaxData::Error, error_msg }
        end
        search = TaxDataSearch.new @browser
        mock(search).puts(error_msg)
        search.collect_property_details @address
      end

    end

  end

end
