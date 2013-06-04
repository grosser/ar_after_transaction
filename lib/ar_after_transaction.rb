require 'active_record'
require 'ar_after_transaction/version'

module ARAfterTransaction
  module ClassMethods
    def transaction(*args, &block)
      clean = true
      super
    rescue Exception
      clean = false
      raise
    ensure
      unless transactions_open?
        callbacks = delete_after_transaction_callbacks
        callbacks.each(&:call) if clean
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
      connection.normally_open_transactions ||= 0
    end

    def normally_open_transactions=(value)
      connection.normally_open_transactions = value
    end

    private

    def transactions_open?
      connection.open_transactions > normally_open_transactions
    end

    def delete_after_transaction_callbacks
      result = connection.after_transaction_callbacks || []
      connection.after_transaction_callbacks = []
      result
    end
  end

  module InstanceMethods
    def after_transaction(&block)
      self.class.after_transaction(&block)
    end
  end
end

module ARAfterTransactionConnection
  def self.included(base)
    base.class_eval do
      attr_accessor :normally_open_transactions
      attr_accessor :after_transaction_callbacks
    end
  end
end

ActiveRecord::Base.send(:extend, ARAfterTransaction::ClassMethods)
ActiveRecord::Base.send(:include, ARAfterTransaction::InstanceMethods)
ActiveRecord::ConnectionAdapters::AbstractAdapter.send(:include, ARAfterTransactionConnection)
