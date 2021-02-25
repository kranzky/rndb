# frozen_string_literal: true

module RnDB
  class Database
    attr_accessor :prng
    attr_reader :seed

    # Opens a new fake database. A seed for the PRNG may be optionally supplied.
    def initialize(seed=Time.now.to_i)
      raise "database already open" unless Thread.current[:rndb_database].nil?
      Thread.current[:rndb_database] = self
      @prng = Random
      @seed = seed
    end

    # Add a Table to the database, specifying the number of records to simulate.
    def add_table(klass, size)
      klass.send(:_migrate, size.to_i)
    end

    # Dump the table schemas as a hash.
    def schema
      Thread.current[:rndb_tables]
    end
  end
end
