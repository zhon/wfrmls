
module Wfrmls
  class Reo
    def initialize(residential_search)
      @search = residential_search
    end

    def find
      @search.goto_search_page
      @search.status('Active')
      @search.county('Davis')
    end
  end
end
