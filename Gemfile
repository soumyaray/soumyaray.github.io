source 'https://rubygems.org' # use 'http://' if OpenSSL not installed
ruby File.read('.ruby-version').chomp

gem 'rack', '>= 2.0.6'
gem 'ffi', '>= 1.9.24'
gem 'slim', '~> 4.0' # tilt:activeview error with slim 5

# For common CLI tasks
gem 'rake'

# For faster file watcher updates on Windows:
gem 'wdm', '~> 0.1.0', platforms: [:mswin, :mingw]

# windows does not come with time zone data
gem 'tzinfo-data', platforms: [:mswin, :mingw]

# Middleman Gems
gem 'middleman', '~> 4.4.3'
gem 'middleman-livereload', '~> 3.4.6' # (see config.rb)
