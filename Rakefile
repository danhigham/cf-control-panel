require 'bundler'
require 'rake'
Bundler.setup

$:.push File.expand_path("../lib", __FILE__)

Dir["lib/tasks/*.rake"].sort.each { |ext| load ext }