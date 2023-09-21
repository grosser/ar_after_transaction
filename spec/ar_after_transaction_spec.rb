# frozen_string_literal: true

require 'spec_helper'

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

  it 'does not execute when transaction was rolled back' do
    User.test_callbacks = [:do_after, :do_normal, :oops]
    expect(-> { User.create! }).to raise_error(AnExpectedError)
    expect(User.test_stack).to eq [:normal]
  end

  it 'does not execute when transaction gets rolled back by ActiveRecord::Rollback '\
     'raised in an after_create callback' do
    User.test_callbacks = [:do_after, :do_normal, :raise_rollback]
    User.create!
    expect(User.test_stack).to eq [:normal]
  end

  it 'does not execute when transaction gets rolled back by ActiveRecord::Rollback outside of the model' do
    User.test_callbacks = [:do_after, :do_normal]
    user = nil
    ActiveRecord::Base.transaction do
      user = User.create!
      raise ActiveRecord::Rollback
    end
    expect(User.test_stack).to eq [:normal]
  end

  it 'clears transaction callbacks when transaction fails' do
    User.test_callbacks = [:do_after, :do_normal, :oops]
    expect(-> { User.create! }).to raise_error(AnExpectedError)
    User.test_callbacks = [:do_normal]
    User.create!
    expect(User.test_stack).to eq [:normal, :normal]
  end

  it 'executes when no transaction is open' do
    user = User.new
    user.do_after
    user.do_normal
    expect(User.test_stack).to eq [:after, :normal]
  end

  it 'executes when open transactions are normal' do
    User.normally_open_transactions = 1
    User.test_callbacks = [:do_after, :do_normal]
    User.create!
    expect(User.test_stack).to eq [:after, :normal]
  end

  it 'does not execute the same callback twice when successful' do
    User.test_callbacks = [:do_after, :do_normal]
    User.create!
    User.create!
    expect(User.test_stack).to eq [:normal, :after, :normal, :after]
  end

  it 'does not execute the same callback twice when failed' do
    User.test_callbacks = [:do_after, :do_normal, :oops]
    expect(-> { User.create! }).to raise_error(AnExpectedError)
    expect(-> { User.create! }).to raise_error(AnExpectedError)
    expect(User.test_stack).to eq [:normal, :normal]
  end

  it 'does not crash with additional options' do
    expect(-> { User.transaction(requires_new: true) { true } }).not_to raise_error
  end

  describe '.normally_open_transactions' do
    subject(:transactions) { User.normally_open_transactions }

    it 'uses 0 by default' do
      expect(transactions).to eq 0
    end

    it 'can set normally open transactions' do
      User.normally_open_transactions = 5
      expect(transactions).to eq 5
    end

    it 'sets them globally' do
      User.normally_open_transactions = 5
      expect(ActiveRecord::Base.normally_open_transactions).to eq 5
    end
  end
end

describe 'A normal ActiveRecord subclass' do
  it 'does not get polluted' do
    expect(User.const_defined?('VERSION')).to be_falsey
  end
end
