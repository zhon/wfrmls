# encoding: UTF-8

require 'wfrmls/navigator/tax_data'
require 'configliere'

require 'nokogiri'

module Wfrmls
  class TaxDataSearch

    def initialize(ie)
      @ie = ie
    end

    def collect_property_details(addr)
      Navigator::TaxData.new(@ie).go addr
      doc = Nokogiri.parse @ie.html
      self.class.send(self.class.choose_collection_style(doc), doc)
    rescue Navigator::Error => e
      puts e.message
    end

    def self.choose_collection_style doc
      /(20\d\d)/ =~ doc.css('th.details-head').text
      if $1.to_i >= 2013
        :collect_details
      else
        :collect_details_old_school
      end
    end

    def self.sibling_text element
      nbsp2sp element.parent.search('td').text.strip
    end

    def self.collect_details doc
      details = {}
      doc.search('tr/th').each do |item|
        case nbsp2sp(item.text)
        when /NAME:/
          details[:owner] = sibling_text item
        when /ADDRESS:/
          details[:address] = sibling_text item
        when /MARKET VALUE:/
          details[:tax_value] = sibling_text item
        when /ACCOUNT SPECIFIC INFO \(1\):/
          sibling_text(item) =~ /Land Gross Acres: ([.0-9]+)/
          details[:lot_size] = $1
        when /IMPROVEMENT SPECIFIC INFO \(1\)/
          text = sibling_text(item) 
          text =~ /Total SqFt.: ([0-9]+)/
          details[:house_size] = $1
          text =~ /Built As Type: (.*?) \xE2\x80\xA2/
          details[:type] = $1
          text =~ /Room Count: (\d+)/
          details[:rooms] ||= {}
          details[:rooms][:total] = $1.to_i
          text =~ /Bedroom Count: (\d+)/
          details[:rooms][:bedrooms] = $1.to_i
          text =~ /Bath Count: ([\d.])/
          details[:rooms][:baths] = $1
          text =~ /Built As Year Built: (\d+)/
          details[:year_built] = $1.to_i


        end
      end
      details

          #details[:exterior][:wall] = $1
          #details[:exterior][:masonry_trim] = $1
          #details[:parking] = nil
          #details[:parking][x.strip] = y.to_i
    end

    def self.collect_details_old_school doc
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
