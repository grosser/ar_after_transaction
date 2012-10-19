require "spec_helper"

class AnExpectedError < Exception
end

class User
  has_many :log_entries

  cattr_accessor :test_callbacks, :test_stack
  self.test_stack = []
  self.test_callbacks = []

  after_create :create_log_entry, :call_test_callbacks
  def call_test_callbacks
    self.class.test_callbacks.map {|callback| send(callback) }.last
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

  def create_log_entry
    # So that we can test that records created in another table also get rolled back
    entry = log_entries.create!(logged_changes: changes)
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
    User.delete_all
    LogEntry.delete_all
  end

  it "has a VERSION" do
    ARAfterTransaction::VERSION.should =~ /^\d+\.\d+\.\d+$/
  end

  it "executes after an explicit transaction commit" do
    called_after_transaction = false
    ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.open_transactions.should == 1
      User.create!
      ActiveRecord::Base.after_transaction do
        called_after_transaction = true
      end
    end
    called_after_transaction.should be_true
  end

  it "executes after an explicit transaction commit, with a loop (demonstrates use of closures)" do
    events = []
    ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.open_transactions.should == 1
      ('A'..'C').each_with_index do |name, i|
        user = User.create! :name => name
        ActiveRecord::Base.after_transaction do
          # By the time this is executed, *all* of the users have been created, but we still have a
          # reference to the i and user for this particular user record.
          events << "Created #{user.name} (#{i+1} of #{User.count} users)"
        end
      end
      events << "Finished loop"
      ActiveRecord::Base.after_transaction do
        events << "Transaction committed"
      end
    end
    events.should == [
      "Finished loop",
      "Created A (1 of 3 users)",
      "Created B (2 of 3 users)",
      "Created C (3 of 3 users)",
      "Transaction committed"
    ]
  end

  it "executes after an automatic transaction commit" do
    User.test_callbacks = [:do_after, :do_normal]
    user = User.create!
    User.test_stack.should == [:normal, :after]
    user.log_entries(true); user.should have(1).log_entry
    user.log_entries.all {|_| _.should be_persisted }
  end

  it "does not execute when transaction gets rolled back by an exception" do
    User.test_callbacks = [:do_after, :do_normal, :oops]
    lambda {
      User.create!
    }.should raise_error(AnExpectedError)
    User.test_stack.should == [:normal]
  end

  it "does not execute when transaction gets rolled back by ActiveRecord::Rollback raised in an after_create callback" do
    User.test_callbacks = [:do_after, :do_normal, :raise_rollback]
    user = User.create!
    User.test_stack.should == [:normal]
    user.should be_new_record
    user.log_entries(true); user.should have(0).log_entries
  end

  it "does not execute when transaction gets rolled back by ActiveRecord::Rollback outside of the model" do
    User.test_callbacks = [:do_after, :do_normal]
    user = nil
    ActiveRecord::Base.transaction do
      user = User.create!
      raise ActiveRecord::Rollback
    end
    User.test_stack.should == [:normal]
    user.log_entries(true); user.should have(0).log_entries
  end

  it "clears transation callbacks when transaction fails" do
    User.test_callbacks = [:do_after, :do_normal, :oops]
    lambda {
      User.create!
    }.should raise_error(AnExpectedError)
    User.test_callbacks = [:do_normal]
    User.create!
    User.test_stack.should == [:normal, :normal]
  end

  it "executes when no transaction is open" do
    user = User.new
    user.do_after
    user.do_normal
    User.test_stack.should == [:after, :normal]
  end

  it "executes when open transactions are normal" do
    User.normally_open_transactions = 1
    User.test_callbacks = [:do_after, :do_normal]
    User.create!
    User.test_stack.should == [:after, :normal]
  end

  it "does not execute the same callback twice when successful" do
    User.test_callbacks = [:do_after, :do_normal]
    User.create!
    User.create!
    User.test_stack.should == [:normal, :after, :normal, :after]
  end

  it "does not execute the same callback twice when failed" do
    User.test_callbacks = [:do_after, :do_normal, :oops]
    lambda {
      User.create!
    }.should raise_error(AnExpectedError)
    lambda {
      User.create!
    }.should raise_error(AnExpectedError)
    User.test_stack.should == [:normal, :normal]
  end

  it "does not crash with additional options" do
    User.transaction(:requires_new => true){}
  end

  describe :normally_open_transactions do
    it "uses 0 by default" do
      User.normally_open_transactions.should == 0
    end

    it "can set normally open transactions" do
      User.normally_open_transactions = 5
      User.normally_open_transactions.should == 5
    end

    it "sets them globally" do
      User.normally_open_transactions = 5
      ActiveRecord::Base.normally_open_transactions.should == 5
    end
  end
end
