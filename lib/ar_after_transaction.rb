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
      if transactions_open?
        execute_after_transaction_callbacks if clean
        clear_transaction_callbacks
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
      connection.open_transactions >= normal_transactions
    end

    def normal_transactions_depth
      Rails.env.test? ? 1 : 0
    end

    def execute_after_transaction_callbacks
      @@after_transaction_hooks.each { |hook| hook.call }
    end

    def clear_transaction_callbacks
      @@after_transaction_hooks.clear
    end
  end

  def after_transaction(&block)
    self.class.after_transaction(&block)
  end
end

ActiveRecord::Base.send(:include, ARAfterTransaction)