require 'wfrmls/reo'

require 'test/unit'
require 'flexmock/test_unit'

module Wfrmls
  class ReoTest < Test::Unit::TestCase
    def setup
      @search = flexmock('residential_search')
      @search.should_ignore_missing
      @reo = Reo.new(@search)
    end

    def test_we_goto_search_page
      @search.should_receive(:goto_search_page).once
      @reo.find
    end

    def test_status_is_active
      @search.should_receive(:status).once
      @reo.find
    end

    def test_selecting_county
      @search.should_receive(:county).once
      @reo.find
    end

  end
end
