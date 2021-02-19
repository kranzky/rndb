#!/usr/bin/env ruby

require 'digest'
require 'crypt/isaac'
require 'benchmark'

module RNDB
  class Database
    def initialize(seed=Time.now.to_i)
      @seed = seed
    end

    def generate(table, row)
      case table
      when :ball
        _generate_ball(row)
      when :person
        _generate_person(row)
      end
    end

    private

    def _generate_ball(row)
      {
        colour: _generate_colour(row),
        transparent: _generate_transparent(row),
        weight: _generate_weight(row),
        material: _generate_material(row)
      }
    end

    def _generate_person(row)
      {
        sex: _generate_sex(row),
        age: _generate_age(row),
        race: _generate_race(row),
        name: _generate_name(row),
        spouse: _generate_spouse(row)
      }
    end

    def _generate_colour(row)
      _seed(:ball, :colour, row)
      Crypt::ISAAC.rand(100)
    end

    def _generate_transparent(row)
      _seed(:ball, :transparent, row)
      Crypt::ISAAC.rand(100)
    end

    def _generate_weight(row)
      _seed(:ball, :weight, row)
      Crypt::ISAAC.rand(100)
    end

    def _generate_material(row)
      _seed(:ball, :material, row)
      Crypt::ISAAC.rand(100)
    end

    def _generate_sex(row)
      _seed(:person, :sex, row)
      Crypt::ISAAC.rand(100)
    end

    def _generate_age(row)
      _seed(:person, :sex, row)
      Crypt::ISAAC.rand(100)
    end

    def _generate_race(row)
      _seed(:person, :race, row)
      Crypt::ISAAC.rand(100)
    end

    def _generate_name(row)
      _seed(:person, :name, row)
      Crypt::ISAAC.rand(100)
    end

    def _generate_spouse(row)
      _seed(:person, :spouse, row)
      Crypt::ISAAC.rand(100)
    end

    def _seed(table, col, row)
      value = [@seed, table, col, row].join('-')
      digest = Digest::SHA256.hexdigest(value)
      retval = digest.to_i(16) % 18446744073709551616
      Crypt::ISAAC.srand(retval)
      nil
    end
  end

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

SEED = 137
DB = RNDB::Database.new(SEED)
# DB.create_table(:ball, 1_000_000)
puts DB.generate(:ball, 0)
puts DB.generate(:person, 0)
