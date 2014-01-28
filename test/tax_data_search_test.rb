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

  describe 'choose_collection_style' do

    it 'when update < 2013 use old school method' do
      doc = stub!
      stub(doc).css.stub!.text { '2012' }
      f = TaxDataSearch.choose_collection_style doc
      f.must_equal :collect_details_old_school
    end

  end

end
