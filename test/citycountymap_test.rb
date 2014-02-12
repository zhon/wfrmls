require 'wfrmls/citycountymap'

require 'test/unit'
#require 'flexmock/test_unit'

module Wfrmls
  class CityCountyMapTest < Test::Unit::TestCase
    def test_this
      assert_equal 'Davis', CityToCounty['Layton']
    end
  end
end
