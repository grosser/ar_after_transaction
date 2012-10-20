source :rubygems

puts ENV['RAILS']

group :dev do
  gem 'rake'
  gem 'rspec', '~>2'
  gem 'mysql'
  gem 'activerecord', ENV['RAILS'] || '~>3', :require => 'active_record'
end
