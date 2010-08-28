require "spec/spec_helper"

describe ARAfterTransaction do
  it "has a VERSION" do
    ARAfterTransaction::VERSION.should =~ /^\d+\.\d+\.\d+$/
  end
end