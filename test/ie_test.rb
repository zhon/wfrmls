require 'wfrmls/ie'

require 'test/unit'
require 'flexmock/test_unit'

class WfrmlsTest < Test::Unit::TestCase
  def test_show_tax_data_with_nothing_found
    ie = flexmock('ie') do |item|
      #item.should_receive(:table)
      #item.should_receive(:rows)
    end
    addr = flexmock('addr') do |item|
      item.should_receive(:number).returns('1')
      item.should_receive(:to_s).and_return('address')
    end
    ie = Wfrmls::IE.new(ie, nil)
    flexmock(ie) do |m| 
      m.should_receive(:goto)
      m.should_receive(:find_tax_data_rows_by_house_and_street).
        and_return([])

      m.should_receive(:puts).with('address not found in tax data')
    end

    ie.show_tax_data(addr)
  end

  def xxxtest_collect_property_details
    ie = Watir::Browser.new
    ie = Wfrmls::IE.new(ie, nil, nil)

    addr = StreetAddress::US.parse('3537 W 2400 S, SYRACUSE, UT')
    ie.collect_property_details(addr)
  end
end
