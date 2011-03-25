source "http://rubygems.org"
# gemspec

gem "activesupport", '>= 3.0.0'
gem "httparty"
gem "nokogiri"
gem "deep_cloneable"
gem 'rack', :git => 'git://github.com/rack/rack.git'
gem "liquid"
gem 'kaminari', :git => 'https://github.com/amatsuda/kaminari.git'
gem "carrierwave", :git => "git://github.com/jnicklas/carrierwave.git"

group :development do
  gem "sqlite3-ruby", :require => "sqlite3"
  gem "annotate"
  gem "bluecloth"
  gem "yard"
  gem "bundler"
  gem "jeweler"
  gem "rcov"
  gem "reek"
end

group :test do
  gem "timecop"
  gem "capybara", ">= 0.4.0"
  gem "mocha", :require => "mocha"
  gem "fakeweb"
  gem "factory_girl", :require => "factory_girl", :git => "git://github.com/thoughtbot/factory_girl.git"
  gem "shoulda", :require => "shoulda"
  gem "test_benchmarker"
  gem "rack-test", :require => "rack/test"
end