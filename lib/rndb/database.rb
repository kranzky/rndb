# frozen_string_literal: true

module RnDB
  class Database
    attr_accessor :prng
    attr_reader :seed

    # Opens a new fake database. A seed for the PRNG may be optionally supplied.
    def initialize(seed = Time.now.to_i)
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

    # Clear overridden state.
    def reset
      schema.each_value { |table| table[:state] = {} }
    end

    # Dump just the overridden state as a hash.
    def state
      schema.transform_values do |table|
        table[:state]
      end
    end

    # Load state from the given hash.
    def load(state)
      state.each do |name, value|
        schema[name][:state] = value
      end
    end

    class << self
      # Get a connection to the database
      def conn
        Thread.current[:rndb_database]
      end
    end
  end
end
