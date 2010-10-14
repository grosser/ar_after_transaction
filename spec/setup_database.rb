ActiveRecord::Base.establish_connection(
  :adapter => "mysql", # need something that has transactions...
  :database => "ar_after_transaction"
)

ActiveRecord::Base.connection.execute('drop table if exists users')
ActiveRecord::Schema.define(:version => 1) do
  create_table :users do |t|
    t.string :name
    t.timestamps
  end
end

#require 'logger'
#ActiveRecord::Base.logger = Logger.new(STDOUT)

class User < ActiveRecord::Base
end
