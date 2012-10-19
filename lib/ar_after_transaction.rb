require 'active_record'
require 'ar_after_transaction/version'

module ARAfterTransaction
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    @@after_transaction_callbacks = []

    def transaction(*args, &block)
      super
    ensure
      unless transactions_open?
        callbacks = delete_after_transaction_callbacks
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

module AfterCommit
  module ActiveRecord
    module ConnectionAdapters # :nodoc:
      module DatabaseStatements

        # Would prefer to hook into this method, but this doesn't get called because MySQLAdapter
        # overrides the commit_db_transaction and doesn't call super so
        # AbstractAdapter#commit_db_transaction doesn't get called.
       #def commit_db_transaction(*args)
       #  super
       #end

        def commit_transaction_records(*args)
          super
          callbacks = ::ActiveRecord::Base.delete_after_transaction_callbacks
          callbacks.each(&:call)
        end
      end
    end
  end
end

ActiveRecord::ConnectionAdapters::AbstractAdapter.class_eval do
  include AfterCommit::ActiveRecord::ConnectionAdapters::DatabaseStatements
end
