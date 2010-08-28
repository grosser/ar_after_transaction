require 'rubygems'
$LOAD_PATH << "lib"
require "init"
require "spec/setup_database"

class FakeEnv
  def initialize(env)
    @env = env
  end

  def test?
    @env == 'test'
  end
end

module Rails
  def self.env
    @@env
  end

  def self.env=(env)
    @@env = FakeEnv.new(env)
  end

  self.env = 'development'
end