#!/usr/bin/env ruby

require 'digest'
require 'crypt/isaac'
require 'benchmark'

module RNDB
  class Database
    def initialize(seed=Time.now.to_i)
      @seed = seed
    end

    def seed(table, col, row)
      value = [@seed, table, col, row].join('-')
      puts value
      digest = Digest::SHA256.hexdigest(value)
      puts digest
      retval = digest.to_i(16) % 18446744073709551616
      Crypt::ISAAC.srand(retval)
      retval
    end
  end

# Crypt::ISAAC.srand(seed)
# 10.times { puts Crypt::ISAAC.rand(100) }

  class Table
    include Comparable

    def initialize
      @attributes = {}
    end

    def <=>(other)
      self.id <=> other.id
    end

    def save
    end
  end

  class Query
    include Enumerable

    def each
      raise
    end
  end
end

class Ball < RNDB::Table
# property :colour, values: [:red, :green, :blue], indexed: true
# property :transparent, values: [false, true], indexed: true
# property :weight
# property :material

# def partner
#   offset = Person.index(gender: gender, marital_status: true).find(id)
#   Person.where(gender: opposite, marital_status: true)[offset]
# end

# def children
# end
end

SEED = 137
DB = RNDB::Database.new(SEED)
puts DB.seed(:balls, :colour, 1)

#balls = DB.create_table(:balls, 1_000_000_000)
#balls.add_col(:colour) do |id, total, prng|
#end
#{ red: 0.1, green: 0.4, blue: 0.3, yellow: 0.2 })
#balls.add_col(:weight, generator)
#balls.add_col(:name) do |id, total, prng|
  # use prng to generate the thing
#end

#puts balls[65536]
# puts balls.where(:colour => blue).count
