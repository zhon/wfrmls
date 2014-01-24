require 'wfrmls/citycountymap'
require 'wfrmls/authenticator'

module Wfrmls
  module TaxData
    class Error < Exception; end

    class Navigator
      include AutomaticAuthenticator

      COUNTY_ID_MAP = {
        "Salt Lake" =>"1",
        "Utah" =>"5",
        "Davis" =>"2",
        "Weber" =>"8",
        "Wasatch" =>"4",
        "Summit" =>"3",
        "Morgan" =>"9",
        "Rich" =>"11",
        "Box Elder" =>"12",
        "Carbon" =>"26",
        "Tooele" =>"7",
        "Uintah" =>"28",
        "Cache" =>"10",
        "Sanpete" =>"14"
      }

      # Setting @ie for Authenticator
      def initialize browser
        @browser = browser
        @ie = @browser
      end

      def go street_address
        result = reduce_rows(
          hit_url(street_address),
          street_address,
          [:by_street, :by_prefix_and_suffix, :by_owner]
        )
        case result.size
        when 0
          raise Error, "'#{street_address}' not found in tax data"
        when 1
          click_link result.first
        else
          raise Error, mutiple_match_message(result)
        end
      end

      def hit_url street_address
        county_id = COUNTY_ID_MAP[CityToCounty[street_address.city]]
        goto "http://www.utahrealestate.com/taxdata/index?county[]=#{county_id}&searchtype=house&searchbox=#{street_address.number}"
        _, *rows = @browser.table(:class, 'tax-data').rows.to_a
        rows
      end

      def candidate_rows addr
        regex = Regexp.new("\\b#{addr.street}\\b", Regexp::IGNORECASE)
        rows = @browser.table(:class, 'tax-data').rows.to_a
        reduce_by rows, regex
      end

      def by_street rows, addr
        reduce_by rows, Regexp.new("\\b#{addr.street}\\b", Regexp::IGNORECASE)
      end

      def by_prefix_and_suffix rows, addr
        reduce_by rows, /\b#{addr.prefix}\b.*\b#{addr.suffix}/
      end

      def by_owner rows, addr
        if owner = Settings.owner
          owner.upcase!
          rows = rows.select do |item|
            item.cell(:index, 2).text.include? owner
          end
        end
        rows
      end

      def reduce_by rows, regex
        rows.select do |item|
          regex.match item.cell(:class, 'last-col').text
        end
      end

      def reduce_rows rows, addr, funcs
        method = funcs.shift
        rows = send(method, rows, addr)
        case rows.size
        when 0
          return []
        when 1
          return [ rows[0] ]
        else
          if funcs.empty?
             rows
          else
            reduce_rows rows, addr, funcs
          end
        end
      end

      def click_link(item)
        item.link(:index, 0).click
      end

      def mutiple_match_message(rows)
        rows.map do |item|
          item.cell(:class, 'last-col').text
        end.unshift("Possible matches:").join("\n")
      end

    end
  end
end
