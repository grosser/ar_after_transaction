# frozen_string_literal: true

require 'active_record'
require 'ar_after_transaction/version'

module ARAfterTransaction
  module ClassMethods
    def after_transaction(&block)
      connection.after_transaction(&block)
    end

    def normally_open_transactions
      connection.normally_open_transactions ||= 0
    end

    delegate :normally_open_transactions=, to: :connection

    private

    def transactions_open?
      connection.send :transactions_open?
    end
  end

  module InstanceMethods
    def after_transaction(&block)
      self.class.connection.after_transaction(&block)
    end
  end
end

module ARAfterTransactionConnection
  def self.included(base)
    base.class_eval do
      attr_accessor :normally_open_transactions
      attr_accessor :after_transaction_callbacks

      alias_method :transaction_without_after, :transaction
      alias_method :transaction, :transaction_with_after
    end
  end

  def transaction_with_after(**args)
    clean = true
    transaction_without_after(**args) do
      yield
    rescue ActiveRecord::Rollback
      clean = false
      raise
    end
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
      self.after_transaction_callbacks ||= []
      self.after_transaction_callbacks << block
    else
      yield
    end
  end

  private

  def transactions_open?
    return false unless active?

    self.normally_open_transactions ||= 0
    open_transactions > normally_open_transactions
  end

  def delete_after_transaction_callbacks
    result = after_transaction_callbacks || []
    self.after_transaction_callbacks = []
    result
  end
end

ActiveRecord::Base.extend ARAfterTransaction::ClassMethods
ActiveRecord::Base.include ARAfterTransaction::InstanceMethods
ActiveRecord::ConnectionAdapters::AbstractAdapter.include ARAfterTransactionConnection
