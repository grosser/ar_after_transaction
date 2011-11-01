task :spec do
  sh "rspec spec"
end

task :default do
  sh "RAILS='~>2' && (bundle || bundle install) && bundle exec rake spec"
  sh "RAILS='~>3' && (bundle || bundle install) && bundle exec rake spec"
end

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = 'ar_after_transaction'
    gem.summary = "Execute irreversible actions only when transactions are not rolled back"
    gem.email = "michael@grosser.it"
    gem.homepage = "http://github.com/grosser/#{gem.name}"
    gem.authors = ["Michael Grosser"]
    gem.add_dependency ['activerecord']
  end

  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler, or one of its dependencies, is not available. Install it with: gem install jeweler"
end
