Do something only after the currently open transactions have finished.

Normally everything gets rolled back when a transaction fails, but you cannot roll back sending an email or adding a job to Resque.

Install
=======
    rails plugin install git://github.com/grosser/ar_after_transaction
or
    gem install ar_after_transaction


Usage
=====
### just-in-time callbacks
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

### General 'this should be rolled back when in a transaction' code like jobs

    class Resque
      def revertable_enqueue(*args)
        ActiveRecord::Base.after_transaction do
          enqueue(*args)
        end
      end
    end

### When not in a transaction
after_transaction will perform the given block immediately

### Transactional fixtures <-> normally_open_transactions
after_transaction assumes zero open transactions.<br/>
If you use transactional fixtures you should change it in test mode.

    # config/environments/test.rb
    config.after_initialize do
      ActiveRecord::Base.normally_open_transactions = 1
    end

### Rails 3: after_commit hook can replace the first usage example:

    class User
      after_commit :send_an_email :on=>:create
      after_create :do_stuff, :oops
      ...
    end

Alternative
===========
[after_commit](https://github.com/pat/after_commit)<br/>
 + threadsafe<br/>
 + more fine-grained callbacks (before_commit, `after_commit`, before_rollback, after_rollback)<br/>
 - doesn't let you define `after_transaction` callbacks *anywhere* like `ar_after_transaction` does (*outside* of the `after_commit`, etc. callbacks which only happen at certain points in the model's life cycle)<br/>
 - more complex<br/>

Authors
=======
[Original idea and code](https://rails.lighthouseapp.com/projects/8994/tickets/2991-after-transaction-patch) from [Jamis Buck](http://weblog.jamisbuck.org/) (post by Jeremy Kemper)

### [Contributors](http://github.com/grosser/ar_after_transaction/contributors)
 - [Bogdan Gusiev](http://gusiev.com)
 - [Benedikt Deicke](http://blog.synatic.net)

[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
Hereby placed under public domain, do what you want, just do not hold me accountable...
