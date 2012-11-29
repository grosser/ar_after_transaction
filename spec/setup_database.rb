ActiveRecord::Base.establish_connection(
  :adapter  => 'sqlite3',
  :database => ':memory:'
)

ActiveRecord::Migration.verbose = false
ActiveRecord::Schema.define(:version => 1) do
  create_table :users do |t|
    t.string :name
    t.timestamps
  end

  create_table :log_entries do |t|
    t.belongs_to :user
    t.string :logged_changes
    t.timestamps
  end
end

# for detailed debugging:
#require 'logger'
#ActiveRecord::Base.logger = Logger.new(STDOUT)

class User < ActiveRecord::Base
end
class LogEntry < ActiveRecord::Base
  serialize :logged_changes
end
