require 'active_record'
require 'ar_after_transaction/version'

module ARAfterTransaction
  module ClassMethods
    def self.extended( base )
      base.class_eval do
        class << self
          alias_method :transaction_without_after, :transaction
          alias_method :transaction, :transaction_with_after
        end
      end
    end

    def transaction_with_after(*args)
      clean = true
      outermost_transaction = true unless transactions_open?
      transaction_without_after(*args) do
        begin
          yield.tap do
            if outermost_transaction
              callbacks = delete_before_transaction_commit_callbacks
              callbacks.each(&:call)
            end
          end
        rescue ActiveRecord::Rollback
          clean = false
          raise
        end
      end
    rescue Exception
      clean = false
      raise
    ensure
      unless transactions_open?
        delete_before_transaction_commit_callbacks
        callbacks = delete_after_transaction_callbacks
        callbacks.each(&:call) if clean
      end
    end

    def before_transaction_commit(&block)
      if transactions_open?
        connection.before_transaction_commit_callbacks ||= []
        connection.before_transaction_commit_callbacks << block
      else
        yield
      end
    end

    def after_transaction(&block)
      if transactions_open?
        connection.after_transaction_callbacks ||= []
        connection.after_transaction_callbacks << block
      else
        yield
      end
    end

    def normally_open_transactions
      @@normally_open_transactions ||= 0
    end

    def normally_open_transactions=(value)
      @@normally_open_transactions = value
    end

    private

    def transactions_open?
      pool = connection_pool
      return false unless pool && pool.active_connection?
      connection.open_transactions > normally_open_transactions
    end

    def delete_after_transaction_callbacks
      result = connection.after_transaction_callbacks || []
      connection.after_transaction_callbacks = []
      result
    end

    def delete_before_transaction_commit_callbacks
      result = connection.before_transaction_commit_callbacks || []
      connection.before_transaction_commit_callbacks = []
      result
    end
  end

  module InstanceMethods
    def after_transaction(&block)
      self.class.after_transaction(&block)
    end

    def before_transaction_commit(&block)
      self.class.before_transaction_commit(&block)
    end
  end
end

module ARAfterTransactionConnection
  def self.included(base)
    base.class_eval do
      attr_accessor :normally_open_transactions
      attr_accessor :after_transaction_callbacks
      attr_accessor :before_transaction_commit_callbacks
    end
  end
end

ActiveRecord::Base.send(:extend, ARAfterTransaction::ClassMethods)
ActiveRecord::Base.send(:include, ARAfterTransaction::InstanceMethods)
ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:include, ARAfterTransactionConnection)
