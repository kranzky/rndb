# frozen_string_literal: true

module RnDB
  class Query
    include Enumerable

    def initialize(table, ids)
      @table, @ids = table, ids
    end

    def count
      @ids.map(&:count).sum
    end

    def [](index)
      @table[_id(index)] if index < count
    end

    def last
      self[-1] unless count.zero?
    end

    def each
      (0...count).each { |index| yield self[index] }
    end

    def pluck(*args)
      (0...count).map do |index|
        if args.count == 1
          @table.value(_id(index), args.first)
        else
          args.map do |property|
            [property, @table.value(_id(index), property)]
          end.to_h
        end
      end
    end

    def sample(limit=1)
      _db.prng.srand
      ids = Set.new
      while ids.count < [limit, count].min
        index = _db.prng.rand(count)
        ids << Slice.new(_id(index), _id(index))
      end
      self.class.new(@table, ids.to_a)
    end

    private

    def _db
      Thread.current[:rndb_database]
    end

    def _id(index)
      index += count while index.negative?
      @ids.each do |range|
        return range.min + index if index < range.count
        index -= range.count
      end
      nil
    end
  end
end
