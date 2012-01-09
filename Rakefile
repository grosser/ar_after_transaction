require 'bundler/gem_tasks'

task :spec do
  sh "rspec spec"
end

task :default do
  sh "RAILS='~>2' && (bundle || bundle install) && bundle exec rake spec"
  sh "RAILS='~>3' && (bundle || bundle install) && bundle exec rake spec"
end

rule /^version:bump:.*/ do |t|
  sh "git status | grep 'nothing to commit'" # ensure we are not dirty
  index = ['major', 'minor','patch'].index(t.name.split(':').last)
  file = 'lib/youtube_search/version.rb'

  version_file = File.read(file)
  old_version, *version_parts = version_file.match(/(\d+)\.(\d+)\.(\d+)/).to_a
  version_parts[index] = version_parts[index].to_i + 1
  new_version = version_parts * '.'
  File.open(file,'w'){|f| f.write(version_file.sub(old_version, new_version)) }

  sh "bundle && git add #{file} Gemfile.lock && git commit -m 'bump version to #{new_version}'"
end
