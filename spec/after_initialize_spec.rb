require 'active_record'
require File.expand_path '../setup_database', __FILE__

railtie = false

begin
  require 'action_controller/railtie'
  railtie = true
rescue LoadError
  puts 'Railtie not loaded, skipping test'
end

if railtie

  module Passthrough
    def self.extended( base )
      base.class_eval do
        class << self
          alias_method :transaction_without_passthrough, :transaction
          alias_method :transaction, :transaction_with_passthrough
        end
      end
    end

    def transaction_with_passthrough(*args, &block)
      transaction_without_passthrough(*args, &block)
    end
  end

  class Railtie < ::Rails::Railtie
    config.after_initialize do
      ActiveRecord::Base.send(:extend, Passthrough)
    end
  end

  module ARAfterTransaction
    class Application < ::Rails::Application
      config.active_support.deprecation = :log

      config.after_initialize do
        require 'ar_after_transaction'
      end
    end
  end
   
  # Initialize the application
  ARAfterTransaction::Application.initialize!

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
        ActiveRecord::Base.transaction do
          # nested transaction should not cause infinitive recursion
        end
        self.class.test_stack << :after
      end
    end

    def do_normal
      self.class.test_stack << :normal
    end

    def oops
      raise AnExpectedError
    end

    def raise_rollback
      raise ActiveRecord::Rollback
    end
  end

  describe ARAfterTransaction do
    before do
      User.normally_open_transactions = nil
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
  end
end