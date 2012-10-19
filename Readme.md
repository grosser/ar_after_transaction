Do something only after the currently open transactions have finished.

Normally everything gets rolled back when a transaction fails, but you cannot roll back sending an email or adding a job to Resque.

To illustrate this, suppose you had an `after_create` callback in your model that deliverd an
e-mail:

    class User
      after_create :deliver_created_notification, :create_log_entry, :something_else

      def deliver_created_notification
        UserMailer.created(self).deliver  # Cannot be rolled back
      end

      def create_log_entry
        entry = log_entries.create!(logged_changes: changes)  # This will be rolled back
      end

      def something_else
        raise ActiveRecord::Rollback
      end
    end

The e-mail in `deliver_created_notification` will get delivered when you call `User.create!` even
though the Rollback in the `something_else` callback caused the record creation to be aborted.

Install
=======

    gem install ar_after_transaction

Add this line to your Gemfile:

    gem 'ar_after_transaction'

and run `bundle install`.

Usage
=====

### Define `after_transaction` callbacks anywhere within a transaction

Inside of a model...

    class User
      after_create :deliver_created_notification, :create_log_entry, :something_else

      def deliver_created_notification
        after_transaction do
          UserMailer.created(self).deliver  # Will not be executed at all if the transaction is rolled back
        end
      end

      def create_log_entry
        entry = log_entries.create!(logged_changes: changes)  # This will be rolled back
      end

      def something_else
        raise ActiveRecord::Rollback
      end
    end

    User.create!  # Won't deliver any e-mails because the transaction was rolled back

In this case, simply using the
[`after_commit`](http://api.rubyonrails.org/classes/ActiveRecord/Transactions/ClassMethods.html#method-i-after_commit)
callbacks provided by Active Record might have been an easier solution:

    class User
      after_commit :deliver_created_notification, :on => :create

      def deliver_created_notification
        UserMailer.created(self).deliver
      end
    end

But there are some cases where an `after_commit` callback on a model won't work. This gem lets you
define an inline `after_commit` callback for a transaction *anywhere*, even outside of a model. For
example:

    ActiveRecord::Base.transaction do
      @import_file.each_row do |row|
        thing = Thing.create!(row)

        ActiveRecord::Base.after_transaction do
          send_notifications_for(thing)
          thing.rebuild_thumbnails
        end

        if error_condition || user_wants_to_abort?
          raise ActiveRecord::Rollback
        end
      end
    end

### Add `after_commit` callbacks around anything that should not happen if a transaction is rolled back

#### ActionMailer

If you use ActionMailer, you can create a `deliver_on_commit` helper method:

    Mail::Message.class_eval do
      def deliver_on_commit
        ActiveRecord::Base.after_transaction { deliver }
      end
    end

which will allow you to do this:

    UserMailer.created(self).deliver_on_commit

This makes our original example even more concise

    class User
      after_create :deliver_created_notification

      def deliver_created_notification
        UserMailer.created(self).deliver_on_commit
      end
    end

... which might even be clearer and better than using ActiveRecord's `after_commit` callbacks:

    class User
      after_commit :deliver_created_notification, :on => :create

      def deliver_created_notification
        UserMailer.created(self).deliver
      end
    end

#### Resque

    Resque.class_eval do
      def self.enqueue_on_commit(*args)
        ActiveRecord::Base.after_commit do
          enqueue(*args)
        end
      end
    end

will allow you to do this:

    Resque.enqueue_on_commit(Archive, self.id)

### When not in a transaction
after_transaction will perform the given block immediately

### Transactional fixtures <-> normally_open_transactions
after_transaction assumes zero open transactions.<br/>
If you use transactional fixtures you should change it in test mode.

    # config/environments/test.rb
    config.after_initialize do
      ActiveRecord::Base.normally_open_transactions = 1
    end

Alternative
===========
Rails 3+
 - basic support is built in, use it if you can!
 - `after_commit :foo`
 - `after_commit :bar, :on => :create / :update`

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

[Michael Grosser](http://grosser.it)<br/>
michael@grosser.it<br/>
Hereby placed under public domain, do what you want, just do not hold me accountable...
