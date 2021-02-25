# frozen_string_literal: true

module RnDB
  class Query
    include Enumerable

    def initialize(table, ids)
      @table, @ids = table, ids
    end

    def count
      @ids.count
    end

    def [](index)
      @table[@ids[index]]
    end

    def last
      self[-1]
    end

    def each
      @ids.each { |id| yield @table[id] }
    end

    def pluck(*args)
      @ids.map do |id|
        if args.count == 1
          @table.value(id, args.first)
        else
          args.map do |property|
            [property, @table.value(id, property)]
          end.to_h
        end
      end
    end

    def sample(limit=1)
      _db.prng.srand
      self.class.new(@table, @ids.sample(limit, _db.prng))
    end

    private

    def _db
      Thread.current[:rndb_database]
    end
  end
end
