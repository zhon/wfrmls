require 'Wfrmls/settings'

module Wfrmls
  class Reo
    def initialize(residential_search)
      @search = residential_search
    end

    def find
      @search.goto_search_page
      @search.status('Active')
      @search.county(Settings.county || 'Davis')
      #@search.city('Kaysville')
      @search.short_sale(false)
      @search.property_type('Single Family')
      @search.owner_type_not_owner_agent
      #exclude mobile, Townhouse, condo, twin
      @search.year_built_range(1950, nil)
      @search.execute_commands
      @search.show_listings
    end
  end
end
