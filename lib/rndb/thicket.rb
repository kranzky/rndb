# frozen_string_literal: true

module RnDB
  class Thicket
    include Enumerable

    def initialize(ids)
      @ids = Array(ids)
    end

    # number of IDs
    def count
    end

    # return the ID at the given index
    def [](index)
    end

    # return the index of the given ID
    def index(id)
    end

    # iterate through values
    def each
    end

    # return a sampling
    def sample(num=1)
    end

    # intersect two thickets
    def &(other)
    end
  end
end
