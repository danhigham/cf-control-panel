require 'sinatra/base'

module Sinatra
  module NavigationHelpers
    
    def active_link(link_name)
      return if not request.env["PATH_INFO"].start_with? link_name
      "active" 
    end

  end
end