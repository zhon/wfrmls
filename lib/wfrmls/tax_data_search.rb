# encoding: UTF-8

require 'wfrmls/citycountymap'
require 'configliere'

module Wfrmls
  class TaxDataSearch
    include AutomaticAuthenticator

    def initialize(ie)
      @ie = ie
    end

    def collect_property_details(addr)
      show_tax_data(addr) unless @ie.url.include? 'taxdata/details'

      doc = @ie.xmlparser_document_object

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

    def show_tax_data(addr)
      rows = find_tax_data_rows_by_house_and_street(addr)
      case rows.size
      when 0
        puts "#{addr} not found in tax data"
      when 1
        click_link rows[0]
      else
        regex = /\b#{addr.prefix}\b.*\b#{addr.suffix}/
        rows = rows.inject([]) do |c, item|
          c << item if regex.match item.cell(:class, 'last-col').text
          c
        end
        case rows.size
        when 0
          puts "#{addr} not found with #{regex}"
        when 1
          click_link rows[0]
        else
          if owner = Settings.owner
            owner.upcase!
            found = false
            rows.each do |item|
              if item.cell(:index, 2).text.include? owner
                click_link rows[0]
                found = true
                break
              end
            end
            mutiple_match_message(rows) unless found
          else
            mutiple_match_message(rows)
          end
        end
      end
    end

    def mutiple_match_message(rows)
      puts 'Possible matches:'
      rows.each do |item|
        puts item.cell(:class, 'last-col').text
      end
    end

    def find_tax_data_rows_by_house_and_street(addr)
      select_county(addr)

      reg = Regexp.new("\\b#{addr.street}\\b", Regexp::IGNORECASE)
      rows = []
      @ie.table(:class, 'tax-data').rows.to_a[1..-1].each do |row|
        if reg.match row.cell(:class, 'last-col').text
          rows << row
        end
      end
      rows
    end

    def select_county(addr)
      goto "http://www.utahrealestate.com/taxdata/index?searchtype=house&searchbox=#{addr.number}"

      # uncheck davis county (it is checked by default)
      @ie.checkbox(:title, 'Davis').clear
      @ie.checkbox(:title, 'Weber').clear
      begin
        @ie.checkbox(:title, CityToCounty[addr.city]).click
      rescue => e
        puts "Invalid city #{addr.city}"
        puts e.backtrace
      end
      @ie.button(:id, 'SEARCH_button').click
    end

    def click_link(item)
      item.link(:index, 0).click
    end

    def nbsp2sp(s)
      s.gsub("\xC2\xA0", ' ')
    end

  end
end
