require "spec/spec_helper"

class AnExpectedError < Exception
end

class User
  cattr_accessor :test_callbacks, :test_stack
  self.test_stack = []
  self.test_callbacks = []

  after_create :do_it
  def do_it
    self.class.test_callbacks.map{|callback| send(callback)}.last
  end

  def do_after
    after_transaction do
      self.class.test_stack << :after
    end
  end

  def do_normal
    self.class.test_stack << :normal
  end

  def oops
    raise AnExpectedError
  end
end

describe ARAfterTransaction do
  before do
    Rails.env = 'development'
    User.send(:transactions_open?).should == false
    User.test_stack.clear
    User.test_callbacks.clear
  end

  it "has a VERSION" do
    ARAfterTransaction::VERSION.should =~ /^\d+\.\d+\.\d+$/
  end

  it "executes after a transaction" do
    User.test_callbacks = [:do_after, :do_normal]
    User.create!
    User.test_stack.should == [:normal, :after]
  end

  it "does not execute when transaction was rolled back" do
    User.test_callbacks = [:do_after, :do_normal, :oops]
    lambda{
      User.create!
    }.should raise_error(AnExpectedError) 
    User.test_stack.should == [:normal]
  end

  it "executes when no transaction is open" do
    user = User.new
    user.do_after
    user.do_normal
    User.test_stack.should == [:after, :normal]
  end

  it "executes when open transactions are normal" do
    Rails.env = 'test'
    User.test_callbacks = [:do_after, :do_normal]
    User.create!
    User.test_stack.should == [:after, :normal]
  end

  it "does not execute the same callback twice when successful" do
    User.test_callbacks = [:do_after, :do_normal]
    User.create!
    User.create!
    User.test_stack.should == [:normal, :after, :normal, :after]
  end

  it "does not execute the same callback twice when failed" do
    User.test_callbacks = [:do_after, :do_normal, :oops]
    lambda{
      User.create!
    }.should raise_error(AnExpectedError)
    lambda{
      User.create!
    }.should raise_error(AnExpectedError)
    User.test_stack.should == [:normal, :normal]
  end
end