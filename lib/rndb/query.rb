# frozen_string_literal: true

module RnDB
  class Query
    include Enumerable

    # Query records of the given table based on the IDs in the supplied Thicket.
    def initialize(table, ids)
      @table, @ids = table, ids
    end

    # Delegate counting to the Thicket.
    def count
      @ids.count
    end

    # Retrieve the ID of an index into this query and use it to instantiate a record.
    def [](index)
      @table[@ids[index]]
    end

    # Implemented to be consistent with #first, which we get by magic.
    def last
      self[-1]
    end

    # Delegate iteration to the Thicket, yielding records to the caller.
    def each
      @ids.each { |id| yield @table[id] }
    end

    # Return an array or a hash of pucked values, avoiding generation of all attributes.
    def pluck(*args)
      @ids.map do |id|
        if args.count == 1
          @table.value(id, args.first)
        else
          args.map do |attribute|
            [attribute, @table.value(id, attribute)]
          end.to_h
        end
      end
    end

    # Return a new query that takes a random sampling of IDs from the current query.
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
