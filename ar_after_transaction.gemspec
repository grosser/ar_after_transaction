$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'ar_after_transaction/version'

Gem::Specification.new "ar_after_transaction", ARAfterTransaction::VERSION do |s|
  s.summary = "Execute irreversible actions only when transactions are not rolled back"
  s.authors = ["Michael Grosser"]
  s.email = "michael@grosser.it"
  s.homepage = "http://github.com/grosser/ar_after_transaction"
  s.files = `git ls-files`.split("\n")
  s.add_runtime_dependency "activerecord"
  s.add_runtime_dependency "railties"
  s.license = "MIT"
end
