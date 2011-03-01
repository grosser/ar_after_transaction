task :spec do
  sh "bundle exec rspec spec"
end

task :rails2 do
  sh "cd spec/rails2 && bundle exec rspec ../../spec"
end

task :default do
  sh "rake spec && rake rails2"
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
