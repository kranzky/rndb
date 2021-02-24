# frozen_string_literal: true

module RnDB
  class Database
    attr_accessor :prng
    attr_reader :seed

    def initialize(seed=Time.now.to_i)
      raise "database already open" unless Thread.current[:rndb_database].nil?
      Thread.current[:rndb_database] = self
      @prng = Random
      @seed = seed
    end

    def add_table(klass, size)
      klass._migrate(size.to_i)
    end

    def schema
      Thread.current[:rndb_tables]
    end
  end
end
