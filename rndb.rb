#!/usr/bin/env ruby

require 'digest'
require 'crypt/isaac'
require 'benchmark'
require 'byebug'
require 'json'

DISTRIBUTIONS = {
  colour: {
    red: 0.3,
    green: 0.1,
    brown: 0.01,
    blue: 0.5,
    orange: 0.09
  },
  transparent: {
    true => 0.1,
    false => 0.9
  },
  weight: {
    light: 0.3,
    medium: 0.6,
    heavy: 0.1
  },
  material: {
    leather: 0.2,
    steel: 0.4,
    wood: 0.3,
    fluff: 0.1
  }
}

SIZE = 1_000_000

module RnDB
  class Table
    def initialize
    end

    def self.column(name, args)
    end

    def all
      # TODO: return a query
    end

    def where(constraints={})
      # TODO: return a query
    end
  end

  class Query
    include Enumerable

    # TODO: include table
    def initialize(ids)
      @ids = ids
    end

    # TODO: override Enumerable#count properly
    def length
      case @ids.first
      when Range
        @ids.map(&:count).sum
      else
        @ids.count
      end
    end

    def [](index)
      _id(index)
      # @table.fetch(_id(index))
    end

    def find(index)
    end

    def find_by(constraint)
    end

    def each
      (0...length).each { |index| yield self[index] }
    end

    def pluck(property)
      # return an array of just that property
    end

    def filter_by(property)
      # return Query of matching IDs
    end

    def sample(count=1)
      # generate count uniq random indexes and map to IDs
      # return Query of matching IDs that we can manipulate
    end

    private

    def _id(index)
      index += self.length if index < 0
      case @ids.first
      when Range
        @ids.each do |range|
          count = range.count
          if index < count
            return range.min + index
          else
            index -= count
          end
        end
        nil
      else
        @ids[index]
      end
    end
  end

  class Database
    def initialize(seed=Time.now.to_i)
      @prng = Random
      @seed = seed
      @tables = Hash.new { |h, k| h[k] = { class: nil, size: 0 } }

      DISTRIBUTIONS.each do |label, distribution|
        raise unless distribution.values.sum == 1
      end

      @mapping = Hash.new do |mapping, property|
        mapping[property] = Hash.new do |distribution, value|
          distribution[value] = []
        end
      end
      
      ranges = [(0...SIZE)]
      DISTRIBUTIONS.each do |label, distribution| 
        ranges = _add_mapping(label, distribution, ranges)
      end
    end

    def set_prng(prng)
      @prng = prng
    end

    def seed_prng(table, col, row)
      raise "#{table} - no such table" if @tables[table][:class].nil?
      raise "#{row} - row out of range" if row < 0 || row >= @tables[table][:size]
      value = [@seed, table, col, row].join('-')
      digest = Digest::SHA256.hexdigest(value)
      seed = digest.to_i(16) % 18446744073709551616
      @prng.srand(seed)
      nil
    end

    def add_table(name, klass, size)
      @tables[name][:class] = klass
      @tables[name][:size] = size
    end

    def generate(table, row)
      raise unless (0...SIZE).include?(row)
      case table
      when :ball
        _generate_ball(row)
      when :person
        _generate_person(row)
      end
    end

    def query(table, constraints={})
      ids = [(0...SIZE)]
      constraints.each do |property, values|
        values = [values] unless values.is_a?(Array)
        ranges = values.map { |value| @mapping[property][value] }.flatten
        ids = _intersect(ids, ranges)
      end
      Query.new(ids)
    end

    private

    def _intersect(ranges_1, ranges_2)
      retval = []
      ranges_1.each do |range_1|
        ranges_2.each do |range_2|
          next if range_1.min > range_2.max
          next if range_2.min > range_1.max
          retval << ([range_1.min, range_2.min].max...[range_1.max, range_2.max].min + 1)
        end
      end
      retval
    end

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
      seed_prng(:ball, :colour, row)
      @prng.rand(100)
    end

    def _generate_transparent(row)
      seed_prng(:ball, :transparent, row)
      @prng.rand(100)
    end

    def _generate_weight(row)
      seed_prng(:ball, :weight, row)
      @prng.rand(100)
    end

    def _generate_material(row)
      seed_prng(:ball, :material, row)
      @prng.rand(100)
    end

    def _generate_sex(row)
      seed_prng(:person, :sex, row)
      @prng.rand(100)
    end

    def _generate_age(row)
      seed_prng(:person, :sex, row)
      @prng.rand(100)
    end

    def _generate_race(row)
      seed_prng(:person, :race, row)
      @prng.rand(100)
    end

    def _generate_name(row)
      seed_prng(:person, :name, row)
      @prng.rand(100)
    end

    def _generate_spouse(row)
      seed_prng(:person, :spouse, row)
      @prng.rand(100)
    end

    def _add_mapping(label, distribution, ranges)
      ranges.each do |range|
        start = range.first
        distribution.each do |value, probability|
          length = (range.count * probability).to_i
          @mapping[label][value] << (start...start+length)
          start += length
        end
      end
      ranges.clear
      @mapping[label].each do |value, distribution|
        ranges << distribution
      end
      ranges.flatten
    end
  end
end

class Ball < RnDB::Table
  column :colour, { red: 0.3, green: 0.1, brown: 0.01, blue: 0.5, orange: 0.09 }
  column :transparent, { true => 0.1, false => 0.9 }
  column :weight_name, { light: 0.3, medium: 0.6, heavy: 0.1 }
  column :material, { leather: 0.2, steel: 0.4, wood: 0.3, fluff: 0.1 }
  column :weight, -> id, prng { 42 }
end

SEED = 137
DB = RnDB::Database.new(SEED)
DB.set_prng(Crypt::ISAAC)
DB.add_table(:ball, Ball, 1_000_000)

#puts Ball.count
#puts Ball.find(13)
#puts Ball.find_by(weight: 42)
#puts Ball.query(:colour => [:red, :blue], :material => :wood).sample(30).pluck(:weight_name)

puts DB.generate(:ball, 0)
puts DB.generate(:ball, 1)
query = DB.query(:ball, :colour => [:red, :blue], :material => :wood)
puts query.length
puts query.lazy.take(3).to_a
