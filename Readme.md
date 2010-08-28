Perform stuff (only) after the currently open transactions have finished.

Normally everything gets rolled back when a transaction fails, but you cannot roll back sending an email or adding a job to Resque.

Its great for just-in-time callbacks:
    class User
      after_create :do_stuff, :oops

      def do_stuff
        after_transaction do
          send_an_email # cannot be rolled back
        end
        comments.build(...) # can be rolled back
      end

      def oops
        raise "do the rolback!"
      end
    end

Or general 'this should be rolled back when in a transaction code like jobs:

    class Resque
      def revertable_enqueue(*args)
        ActiveRecord::Base.after_transaction do
          enqueue(*args)
       end
      end
    end
    
There is a after_commit hook in Rails 3, which can replace the first usage:

    class User
      after_commit :send_an_email :on=>:create
      ater_create :do_stuff, :oops
      ...
    end

after_transaction will behave like it would not exist if you are not in an transaction when calling it.


    rails plugin install git://github.com/grosser/ar_after_transaction
    gem install ar_after_transaction

TODO
=====
 - find out if we are in test mode with or without transactions (atm assumes depth of 1 for 'test' env)


Author
======
Original idea and code comes from: Jeremy Kemper @ https://rails.lighthouseapp.com/projects/8994/tickets/2991-after-transaction-patch 


[Michael Grosser](http://pragmatig.wordpress.com)  
grosser.michael@gmail.com  
Hereby placed under public domain, do what you want, just do not hold me accountable...

