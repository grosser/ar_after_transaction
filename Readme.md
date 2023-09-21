[![Gem Version](https://badge.fury.io/rb/ar_after_transaction.png)](http://badge.fury.io/rb/ar_after_transaction)
![CI](https://github.com/grosser/ar_after_transaction/workflows/CI/badge.svg)

Do something only after the currently open transactions have finished.

Normally everything gets rolled back when a transaction fails, but you cannot roll back sending an email or adding a job to Resque.

Install
=======

```bash
gem install ar_after_transaction
```


Usage
=====

### just-in-time callbacks

```ruby
class User
  after_create :do_stuff, :oops

  def do_stuff
    after_transaction do
      send_an_email # cannot be rolled back
    end
    comments.create(...) # will be rolled back
  end

  def oops
    raise "do the rolback!"
  end
end
```

### General 'this should be rolled back when in a transaction' code like jobs

```ruby
class Resque
  def revertable_enqueue(*args)
    ActiveRecord::Base.after_transaction do
      enqueue(*args)
    end
  end
end
```

### When not in a transaction
after_transaction will perform the given block immediately

### Transactional fixtures <-> normally_open_transactions
after_transaction assumes zero open transactions.<br/>
If you use transactional fixtures you should change it in test mode.

`Rspec:`
```ruby
# spec/rails_helper.rb
  config.before(:suite) do
    ActiveRecord::Base.normally_open_transactions = 1
  end
```

### Rails 3: after_commit hook can replace the first usage example:

```ruby
class User
  after_commit :send_an_email on: :create
  after_create :do_stuff, :oops
  ...
end
```

Alternative
===========

Rails 3+
 - basic support is built in, use it if you can!
 - `after_commit :foo`
 - `after_commit :bar, on: :create / :update`
 - [after_commit everywhere](https://dev.to/evilmartians/rails-aftercommit-everywhere--4j9g)


[after_commit](https://github.com/pat/after_commit)<br/>
 - pro: threadsafe<br/>
 - pro: more fine-grained callbacks (before_commit, `after_commit`, before_rollback, after_rollback)<br/>
 - con: doesn't let you define `after_transaction` callbacks *anywhere* like `ar_after_transaction` does (*outside* of the `after_commit`, etc. callbacks which only happen at certain points in the model's life cycle)<br/>
 - con: more complex<br/>

Authors
=======
[Original idea and code](https://rails.lighthouseapp.com/projects/8994/tickets/2991-after-transaction-patch) from [Jamis Buck](http://weblog.jamisbuck.org/) (post by Jeremy Kemper)

### [Contributors](http://github.com/grosser/ar_after_transaction/contributors)
 - [Bogdan Gusiev](http://gusiev.com)
 - [Benedikt Deicke](http://blog.synatic.net)
 - [Tyler Rick](https://github.com/TylerRick)
 - [Michael Wu](https://github.com/michaelmwu)
 - [C.W.](https://github.com/compwron)
 - [Ben Weintraub](https://github.com/benweint)
 - [Vladimir Temnikov](https://github.com/vladimirtemnikov)
 - [Mark Gangl](https://github.com/attack)

[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
License: MIT<br/>

