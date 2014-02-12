require 'wfrmls/residential_search'

require 'test/unit'
require 'flexmock/test_unit'

require 'wfrmls/settings'


module Wfrmls
  class ResidentialSearchTest < Test::Unit::TestCase
    def xxxtest_really_hitting_website

      search = Wfrmls::ResidentialSearch.new(ie)
      addr = StreetAddressExt.parse('')
      search.find_address(addr)
    end
  end
end
