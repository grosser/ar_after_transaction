require 'active_record'

module ARAfterTransaction
  VERSION = File.read( File.join(File.dirname(__FILE__),'..','VERSION') ).strip

  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    @@after_transaction_callbacks = []

    def transaction(&block)
      clean = true
      super(&block)
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

    private

    def transactions_open?
      connection.open_transactions > normally_open_transactions
    end

    def normally_open_transactions
      Rails.env.test? ? 1 : 0
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
