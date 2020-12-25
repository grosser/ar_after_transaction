require './lib/ar_after_transaction/version'

Gem::Specification.new "ar_after_transaction", ARAfterTransaction::VERSION do |s|
  s.summary = "Execute irreversible actions only when transactions are not rolled back"
  s.authors = ["Michael Grosser"]
  s.email = "michael@grosser.it"
  s.homepage = "http://github.com/grosser/ar_after_transaction"
  s.files = `git ls-files lib Readme.md`.split("\n")
  s.required_ruby_version = '>= 2.4.0'
  s.add_runtime_dependency "activerecord", ">= 4.2.0", "< 6.2"
  s.add_development_dependency "wwtd"
  s.add_development_dependency "bump"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec", "~>2"
  s.add_development_dependency "sqlite3"
  s.add_development_dependency "rails"
  s.license = "MIT"
end
