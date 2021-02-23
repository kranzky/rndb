#!/usr/bin/env ruby

require 'digest'
require 'crypt/isaac'
require 'benchmark'
require 'byebug'
require 'json'
require 'faker'

module RnDB
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
      raise "database already open" unless Thread.current[:rndb_database].nil?
      @prng = Random
      @seed = seed
      @tables = Hash.new { |h, k| h[k] = { class: nil, size: 0 } }
      Thread.current[:rndb_database] = self
    end

    def set_prng(prng)
      @prng = prng
    end

    def get_seed(name, col, row)
      raise "#{table} - no such table" if Thread.current[:rndb_tables][name][:class].nil?
      raise "#{row} - row out of range" if row < 0 || row >= Thread.current[:rndb_tables][name][:size]
      value = [@seed, name, col, row].join('-')
      digest = Digest::SHA256.hexdigest(value)
      digest.to_i(16) % 18446744073709551616
    end

    def seed_prng(table, col, row)
      @prng.srand(get_seed(table, col, row))
    end

    def seed_faker
      Faker::Config.random = @prng
    end

    def add_table(klass, size)
      klass.migrate(size)
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
        name: _generate_ballname(row),
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

    def _generate_ballname(row)
      seed_prng(:ball, :name, row)
      seed_faker
      Faker::Name.name
    end

    def _generate_name(row)
      seed_prng(:person, :name, row)
      seed_faker
      Faker::Name.name
    end

    def _generate_spouse(row)
      seed_prng(:person, :spouse, row)
      @prng.rand(100)
    end
  end

  class Table
    def initialize(id)
      @id = id
    end

    def attributes
      _generate_all
    end

    def to_h
      attributes
    end

    def to_s
      to_h.to_s
    end

    def self.table_name
      self.name.downcase.to_sym
    end

    def self.count
      schema[:size]
    end

    def self.find(id)
      self.new(id)
    end

    def self.schema
      Thread.current[:rndb_tables] ||= Hash.new do |tables, name|
        tables[name] = {
          class: nil,
          size: 0,
          columns: Hash.new do |columns, key|
            columns[key] = {
              distribution: nil,
              mapping: Hash.new do |distribution, value|
                distribution[value] = []
              end,
              generator: nil
            }
          end,
        }
      end
      Thread.current[:rndb_tables][table_name]
    end

    def self.migrate(size)
      raise "table already migrated" unless schema[:class].nil?
      ranges = [(0...size)]
      schema[:columns].each do |property, column|
        distribution = column[:distribution]
        next if distribution.nil?
        raise unless distribution.values.sum == 1
        ranges = self._add_mapping(column, ranges)
      end
      schema[:size] = size
      schema[:class] = self
    end

    # TODO: add generator for each property with accessor that caches results in
    #       attributes, and add attributes method that generates everything
    def self.column(property, *args)
      args.each do |arg|
        index =
          case arg
          when Hash
            :distribution
          when Proc
            :generator
          else
            raise "bad argument"
          end
        schema[:columns][property][index] = arg
      end
    end

    private

    def self._add_mapping(column, ranges)
      ranges.each do |range|
        start = range.first
        column[:distribution].each do |value, probability|
          length = (range.count * probability).to_i
          column[:mapping][value] << (start...start+length)
          start += length
        end
      end
      ranges.clear
      column[:mapping].each do |value, distribution|
        ranges << distribution
      end
      ranges.flatten
    end

    # TODO: generate all the things
    def _generate_all
      @_attributes ||= {}
      @_attributes[:id] ||= @id
      self.class.schema[:columns].keys.each do |name|
        _generate_column(name)
      end
      @_attributes
    end

    def _generate_column(name)
      @_attributes ||= {}
      @_attributes[name] ||=
        begin
          column = self.class.schema[:columns][name]
          value =
            unless column[:mapping].nil?
              column[:mapping].find do |value, ranges|
                ranges.any? { |range| range.include?(@id) }
              end&.first
            end
          unless column[:generator].nil?
            # TODO: seed right here
            if value.nil?
              value = column[:generator].call(@id)
            else
              value = column[:generator].call(@id, value)
            end
          end
          value
        end
    end
  end
end

class Ball < RnDB::Table
  column :colour, {
    red: 0.3,
    green: 0.1,
    brown: 0.01,
    blue: 0.5,
    orange: 0.09
  }
  column :transparent, {
    true => 0.1,
    false => 0.9
  }
  column :weight, {
    light: 0.3,
    medium: 0.6,
    heavy: 0.1
  }, -> id, value do
    42
  end
  column :material, {
    leather: 0.2,
    steel: 0.4,
    wood: 0.3,
    fluff: 0.1
  }
  column :name, -> id do
    "Fred Smith"
  end
end

DB = RnDB::Database.new(137)
DB.set_prng(Crypt::ISAAC)
DB.add_table(Ball, 1_000_000)
# puts JSON.pretty_generate(Thread.current[:rndb_tables])

puts Ball.count
ball = Ball.find(13)
puts ball

#puts Ball.find_by(weight: 42)
#puts Ball.filter_by(:name) { |name| name =~ /John/ }.take(3).to_a
#puts Ball.where(:colour => [:red, :blue], :material => :wood).sample(30).pluck(:weight_name)
#puts Ball.where(:colour => [:red, :blue]).where(:material => :wood).sample(30).pluck(:weight_name)
