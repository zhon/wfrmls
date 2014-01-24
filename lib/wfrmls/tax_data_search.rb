# encoding: UTF-8

require 'wfrmls/citycountymap'
require 'wfrmls/authenticator'
require 'wfrmls/tax_data/navigator'
require 'configliere'

require 'nokogiri'

module Wfrmls
  class TaxDataSearch

    def initialize(ie)
      @ie = ie
    end

    def collect_property_details(addr)
      TaxData::Navigator.new(@ie).go addr
      doc = Nokogiri.parse @ie.html
      self.class.collect_property_details_from_nokogiri(doc)
    rescue TaxData::Error => e
      puts e.message
    end

    def self.collect_property_details_from_nokogiri doc
      details = {}

      doc.search('tr/th').each do |item|
        case nbsp2sp(item.text)
        when /NAME:/
          details[:owner] = item.parent.search('td').text
        when /ADDRESS:/
          details[:address] = item.parent.search('td').text.strip
        when /PARCEL SPECIFIC INFO:/
          nbsp2sp(item.parent.search('td').text) =~ /Total Acres: ([.0-9]+)/
          details[:lot_size] = $1
        when /VALUATION SPECIFIC INFO:/
          nbsp2sp(item.parent.search('td').text) =~ /Final Value: (\$[0-9,]+)/
          details[:tax_value] = $1
        when /GENERAL INFO:/
          data = nbsp2sp(item.parent.search('td').text)
          data =~ /Yr Built: ([0-9]+)/
          details[:year_built] = $1.to_i
          data =~ /Bldg Style: (.*?) \xE2\x80\xA2/
          details[:type] = $1.strip
        when /AREA INFO:/
          house_size = 0
          data = nbsp2sp(item.parent.search('td').text)
          data =~ /Main Floor Area: ([,0-9]+)/
          house_size += $1.sub(',','').to_i if $1
          data =~ /Basement Area: ([,0-9]+)/
          house_size += $1.sub(',','').to_i if $1
          data =~ /Upper Floor Area: ([,0-9]+)/
          house_size += $1.sub(',','').to_i if $1
          details[:house_size] = house_size
        when /EXTERIOR:/
          details[:exterior] ||= {}
          data = nbsp2sp(item.parent.search('td').text)
          data =~ /Ext. Wall Type: (\w+)/
          details[:exterior][:wall] = $1
          data =~ /Masonry Trim: (\w+)/
          details[:exterior][:masonry_trim] = $1
        when /ROOM INFO:/
          details[:rooms] ||= {}
          data = nbsp2sp(item.parent.search('td').text)
          data =~ /Total Rooms: (\d+)/
          details[:rooms][:total] = $1.to_i
          data =~ /Bedrooms: (\d+)/
          details[:rooms][:bedrooms] = $1.to_i
          data =~ /Full Baths: (\d+)/
          br = $1.to_i
          data =~ /1\/2 Baths: (\d+)/
          br += $1.to_i
          data =~ /3\/4 Baths: (\d+)/
          br += $1.to_i
          details[:rooms][:baths] = br
        when /CARPORT & GARAGE INFO:/
          data = nbsp2sp(item.parent.search('td').text)
          details[:parking] = nil
          data.scan(/([\w -]*): ([0-9]+)/) do |x,y|
            details[:parking] ||= {}
            details[:parking][x.strip] = y.to_i
          end
        end
      end
      details
    end

    def self.nbsp2sp(s)
      s.gsub("\xC2\xA0", ' ')
    end

  end
end
