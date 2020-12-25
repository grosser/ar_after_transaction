# frozen_string_literal: true

ActiveRecord::Base.establish_connection(
  adapter: 'sqlite3',
  database: ':memory:'
)

ActiveRecord::Migration.verbose = false
ActiveRecord::Schema.define(version: 1) do
  create_table :users do |t|
    t.string :name
    t.timestamps null: false
  end
end

# for detailed debugging:
# require 'logger'
# ActiveRecord::Base.logger = Logger.new(STDOUT)

class User < ActiveRecord::Base; end
