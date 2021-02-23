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

    def initialize(table, ids)
      @table, @ids = table, ids
    end

    def count
      case @ids.first
      when Range
        @ids.map(&:count).sum
      else
        @ids.count
      end
    end

    def [](index)
      @table[_id(index)]
    end

    def last
      self[-1]
    end

    def each
      (0...count).each { |index| yield self[index] }
    end

    def pluck(*args)
      (0...count).map do |index|
        if args.count == 1
          @table.value(_id(index), args.first)
        else
          Hash[args.map do |property|
            [property, @table.value(_id(index), property)]
          end]
        end
      end
    end

    def sample(limit=1)
      _db.prng.srand
      ids = Set.new
      while ids.count < limit
        index = _db.prng.rand(count)
        ids << _id(index)
      end
      self.class.new(@table, ids.to_a)
    end

    private

    def _db
      Thread.current[:rndb_database]
    end

    def _id(index)
      index += self.count while index < 0
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
    attr_accessor :prng
    attr_reader :seed

    def initialize(seed=Time.now.to_i)
      raise "database already open" unless Thread.current[:rndb_database].nil?
      Thread.current[:rndb_database] = self
      @prng = Random
      @seed = seed
    end

    def add_table(klass, size)
      klass._migrate(size)
    end

    def schema
      Thread.current[:rndb_tables]
    end
  end

  class Table
    class << self
      include Enumerable
    end

    attr_reader :id

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
      name.downcase.to_sym
    end

    def self.[](index)
      self.new(index)
    end

    def self.where(constraints={})
      ids = [(0..._schema[:size])]
      constraints.each do |property, values|
        values = [values] unless values.is_a?(Array)
        column = _schema[:columns][property]
        ranges = values.map { |value| column[:mapping][value] }.flatten
        ids = _intersect(ids, ranges)
      end
      Query.new(self, ids)
    end

    def self.all
      where
    end

    def self.count
      all.count
    end

    def self.last
      all.last
    end

    def self.each(&block)
      all.each(&block)
    end

    def self.pluck(*args)
      all.pluck(args)
    end

    def self.sample(limit=1)
      all.sample(limit)
    end

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
        _schema[:columns][property][index] = arg
      end
      define_method(property) do
        _generate_column(property)
      end
    end

    def self.rand(args)
      _db.prng.rand(args)
    end

    def self.value(id, property)
      return id if property == :id
      column = _schema[:columns][property]
      value =
        unless column[:mapping].nil?
          column[:mapping].find do |value, ranges|
            ranges.any? { |range| range.include?(id) }
          end&.first
        end
      unless column[:generator].nil?
        self._seed_prng(id, property)
        if value.nil?
          value = column[:generator].call(@id)
        else
          value = column[:generator].call(@id, value)
        end
      end
      value
    end

    private

    def self._intersect(ranges_1, ranges_2)
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

    def self._db
      Thread.current[:rndb_database]
    end

    def self._migrate(size)
      raise "table already migrated" unless _schema[:class].nil?
      ranges = [(0...size)]
      _schema[:columns].each do |property, column|
        distribution = column[:distribution]
        next if distribution.nil?
        raise unless distribution.values.sum == 1
        ranges = _add_mapping(column, ranges)
      end
      _schema[:size] = size
      _schema[:class] = self
    end

    def self._schema
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

    def self._add_mapping(column, ranges)
      ranges.each do |range|
        start = range.first
        column[:distribution].each do |value, probability|
          length = (range.count * probability).to_i
          raise if length.zero?
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

    def self._seed_prng(id, property)
      tuple = [_db.seed, table_name, property, id].join('-')
      digest = Digest::SHA256.hexdigest(tuple)
      value = digest.to_i(16) % 18446744073709551616
      _db.prng.srand(value)
      Faker::Config.random = _db.prng
      value
    end

    def _generate_all
      self.class._schema[:columns].keys.each do |name|
        _generate_column(name)
      end
      @_attributes
    end

    def _generate_column(name)
      @_attributes ||= { id: @id }
      @_attributes[name] ||= self.class.value(@id, name)
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
    range =
      case value
      when :light
        (0.1..3.0)
      when :medium
        (3.0..6.0)
      when :heavy
        (6.0..9.9)
      end
    self.rand(range)
  end
  column :material, {
    leather: 0.2,
    steel: 0.4,
    wood: 0.3,
    fluff: 0.1
  }
  column :name, -> id do
    Faker::Games::Pokemon.name
  end
  column :location, -> id do
    Faker::Games::Pokemon.location
  end
  column :move, -> id do
    Faker::Games::Pokemon.move
  end
end

DB = RnDB::Database.new(137)
# DB.prng = Crypt::ISAAC
DB.add_table(Ball, 1_000_000)

query = Ball.where(:colour => [:red, :blue], :material => :wood)
puts "Count: #{query.count}"
puts "First: #{query.first}"
puts "Last: #{query.last}"
puts "Find: #{query.find { |ball| !ball.transparent }}"
puts "Sample..."
puts query.sample(10).pluck(:id, :name, :weight, :move)
puts "Filter..."
puts query.lazy.filter { |ball| ball.move =~ /fire/i }.take(10).to_a

puts "---"

puts "Count: #{Ball.count}"
puts "First: #{Ball.first}"
puts "Last: #{Ball.last}"
puts "Find: #{Ball.find { |ball| ball.location =~ /island/i }}"
puts "Sample..."
puts Ball.sample(10).pluck(:id, :name, :weight, :move)
puts "Filter..."
puts Ball.lazy.filter { |ball| ball.move =~ /fire/i }.take(10).to_a
