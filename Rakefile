# frozen_string_literal: true

require 'bundler/setup'
require 'bundler/gem_tasks'
require 'bump/tasks'
Bump.replace_in_default = Dir["gemfiles/*.lock"]

task default: :spec
task :spec do
  sh 'rspec spec'
end

desc 'Bundle all gemfiles CMD=install'
task :bundle_all do
  Bundler.with_original_env do
    Dir['gemfiles/*.gemfile'].each do |gemfile|
      sh "BUNDLE_GEMFILE=#{gemfile} bundle #{ENV["CMD"]}"
    end
  end
end
