source "http://www.rubygems.org"

gem "sinatra"
gem "sinatra-contrib"
gem "rack-flash"
gem "sequel"
gem "uuidtools"
gem "cfoundry"
gem "omniauth", :git => 'https://github.com/intridea/omniauth.git'
gem "omniauth-twitter", :git => 'https://github.com/arunagw/omniauth-twitter.git'
gem "omniauth-gplus"
gem "rake"

group :test do
  gem 'rack-test'
  gem 'rspec'
end

group :development do
  gem 'sqlite3'
end

group :production do
  gem 'mysql2'
end