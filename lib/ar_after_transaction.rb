require 'active_record'

module ARAfterTransaction
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    @@after_transaction_callbacks = []

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
        @@after_transaction_callbacks << block
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
      connection.open_transactions > normally_open_transactions
    end

    def delete_after_transaction_callbacks
      result = @@after_transaction_callbacks
      @@after_transaction_callbacks = []
      result
    end
  end

  def after_transaction(&block)
    self.class.after_transaction(&block)
  end
end

ActiveRecord::Base.send(:include, ARAfterTransaction)
