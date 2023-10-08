# frozen_string_literal: true

require 'active_record'
require 'rails'
require_relative 'setup_database'

if ActiveRecord::VERSION::MAJOR > 2
  require 'action_controller/railtie' if ActiveRecord::VERSION::MAJOR < 4

  module Passthrough
    def self.extended(base)
      base.class_eval do
        class << self
          alias_method :transaction_without_passthrough, :transaction
          alias_method :transaction, :transaction_with_passthrough
        end
      end
    end

    def transaction_with_passthrough(**args, &block)
      transaction_without_passthrough(**args, &block)
    end
  end

  class Railtie < ::Rails::Railtie
    config.after_initialize do
      ActiveRecord::Base.extend Passthrough
    end
  end

  module ARAfterTransaction
    class Application < ::Rails::Application
      config.eager_load = false
      config.active_support.deprecation = :log

      config.after_initialize do
        require 'ar_after_transaction'
      end
    end
  end

  if defined?(Rack::Session::Cookie)
    Rack::Session::Cookie.send(:define_method, :warn) { |_| } # silence secret warning
  end
  ARAfterTransaction::Application.initialize! # initialize app

  class AnExpectedError < RuntimeError; end

  class User
    cattr_accessor :test_callbacks, :test_stack
    self.test_stack = []
    self.test_callbacks = []

    after_create :do_it
    def do_it
      self.class.test_callbacks.map { |callback| send(callback) }.last
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
      expect(User.send(:transactions_open?)).to be_falsey
      User.test_stack.clear
      User.test_callbacks.clear
    end

    it 'has a VERSION' do
      expect(ARAfterTransaction::VERSION).to match(/^\d+\.\d+\.\d+$/)
    end

    it 'executes after a transaction' do
      User.test_callbacks = [:do_after, :do_normal]
      User.create!
      expect(User.test_stack).to eq [:normal, :after]
    end
  end
end
