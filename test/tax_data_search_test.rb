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

  describe 'collect_details' do

    it 'collects property address' do
      expected = {address: '1216 N NALDER ST'}
      html = <<-EOD
      <tr>
        <th>PROPERTY ADDRESS:</th>
        <td><b>#{expected[:address]}<br /></b></td>
      </tr>
      <tr>
        <th>MAILING ADDRESS:</th>
        <td><b>1216 NORTH NALDER STREET<br />
      LAYTON, UT  84040</b></td>
      </tr>
    EOD
      doc = Nokogiri::HTML html
      TaxDataSearch.collect_details(doc).must_equal expected
    end

    it 'collects house size' do
      html = <<-EOD
      <tr>
        <th>IMPROVEMENT&nbsp;SPECIFIC&nbsp;INFO (1):</th>
        <td>
          <b>Property Type:</b> Residential &bull;
          <b>Occupancy Type:</b> Single Family Res &bull;
          <b>Built As Type:</b> Ranch 1 Story &bull;
          <b>Total Sq Ft.:</b> 1371 &bull;
          <b>Basement Sq Ft.:</b> 1335 &bull;
          <b>Improvement % Complete:</b> 100 % &bull;
          <b>Improvement Condition:</b> Good &bull;
          <b>Improvement Quality:</b> Fair Plus &bull;
          <b>HVAC Type:</b> Forced Air &bull;
          <b># of Stories:</b> 1 &bull;
          <b>Sprinklers Sq Ft.:</b>  &bull;
          <b>Roof Type:</b> Gable &bull;
          <b>Floor Cover:</b> None &bull;
          <b>Built As Foundation:</b> Other &bull;
          <b>Room Count:</b> 8 &bull;
          <b>Bedroom Count:</b> 5 &bull;
          <b>Bath Count:</b> 3 &bull;
          <b>Built As Total Unit Count:</b> 1 &bull;
          <b>Built As Year Built:</b> 1978 &bull;
          <b>Year Remodeled:</b>
        </td>
      </tr>
      EOD
      doc = Nokogiri::HTML html
      details = TaxDataSearch.collect_details(doc)
      details[:house_size].must_equal 1371+1335
    end

    it 'collects garage size from Improvement Detail' do
      expected = {"Basement Double"=>"1", "Built In"=>"669.75"}
      html = <<-EOD
      <tr>
        <th>IMPROVEMENT&nbsp;DETAIL (Garage):</th>
        <td>
          <b>Basement Double:</b> 1 <br />
          <b>Built In:</b> 669.75 <br />
        </td>
      </tr>
      EOD
      doc = Nokogiri::HTML html
      details = TaxDataSearch.collect_details(doc)
      details[:parking].must_equal expected
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
