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

module RN
  class Table
    # all query methods are available here
  end

  class Results
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
      _map(index)
      # find id from index
      # @table.fetch(id)
    end

    def each
      # iterate one at a time
      # yield self[id]
    end

    def all
      self.lazy
    end

    def pluck(property)
      # return an array of just that property
    end

    def filter_by(property)
      # return Results of matching IDs
    end

    def sample(count=1)
      # return Results of matching IDs
    end

    private

    def _map(index)
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

  class DB
    def initialize(seed=Time.now.to_i)
      @seed = seed

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
      Results.new(ids)
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

SEED = 137
DB = RN::DB.new(SEED)
puts DB.generate(:ball, 0)
puts DB.generate(:ball, 1)
puts DB.generate(:person, 0)
query = DB.query(:ball, :colour => [:red, :blue], :material => :wood)
puts query.length
puts query[0]
puts query[query.length-1]
puts query[query.length+1]
puts query[-2]
