require "spec/spec_helper"

describe ARAfterTransaction do
  it "has a VERSION" do
    ARAfterTransaction::VERSION.should =~ /^\d+\.\d+\.\d+$/
  end

  it "executes after a transaction"

  it "does not execute when transaction was rolled back"

  it "executes when no transaction is open"

  it "executes when open transactions are normal"

  it "does not execute the same callback twice when successful"

  it "does not execute the same callback twice when failed"
end