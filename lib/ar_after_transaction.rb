require 'active_record'

module ARAfterTransaction
  VERSION = File.read( File.join(File.dirname(__FILE__),'..','VERSION') ).strip

  def self.included(base)
    base.extend(ClassMethods)

    class << base
      alias_method_chain :transaction, :callbacks
    end
  end

  module ClassMethods
    @@after_transaction_hooks = []

    def transaction_with_callbacks(&block)
      clean = true
      transaction_without_callbacks(&block)
    rescue Exception
      clean = false
      raise
    ensure
      unless transactions_open?
        callbacks = get_after_transaction_callbacks
        execute_callbacks(callbacks) if clean
      end
    end

    def after_transaction(&block)
      if transactions_open?
        @@after_transaction_hooks << block
      else
        yield
      end
    end

    private

    def transactions_open?
      connection.open_transactions > normally_open_transactions
    end

    def normally_open_transactions
      Rails.env.test? ? 1 : 0
    end

    def execute_callbacks(callbacks)
      callbacks.each { |hook| hook.call }
    end

    def get_after_transaction_callbacks
      result = @@after_transaction_hooks
      @@after_transaction_hooks = []
      result
    end
  end

  def after_transaction(&block)
    self.class.after_transaction(&block)
  end
end

ActiveRecord::Base.send(:include, ARAfterTransaction)
