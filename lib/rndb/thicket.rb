# frozen_string_literal: true

module RnDB
  class Thicket
    include Enumerable

    def initialize(min=nil, max=nil)
      @ids = []
      @ids << Slice.new(min, max) unless min.nil? || max.nil?
    end

    def <<(range)
      slice = Slice.new(range.min, range.max)
      raise "Slices in thicket must be disjoint!" unless @ids.all? { |id| (id & slice).nil? }
      @ids << Slice.new(range.min, range.max)
      @ids.sort!
      self
    end

    def &(other)
    end

    def count
      @ids.map(&:count).sum
    end

    def [](index)
      index += count while index.negative?
      @ids.each do |slice|
        return index + slice.min if index < slice.count
        index -= slice.count
      end
      nil
    end

    def last
      self[-1] unless count.zero?
    end

    def index(id)
      start = 0
      @ids.each do |slice|
        return start + id - slice.min if slice.include?(id)
        start += slice.count
      end
      nil
    end

    def each(&block)
      @ids.each { |slice| slice.each(&block) }
    end

    def sample(limit=1, prng=Random)
      ids = Set.new
      limit = [limit, count].min
      while ids.count < limit
        ids << self[prng.rand(count)]
      end
      ids.sort.reduce(self.class.new) do |thicket, id|
        thicket << Slice.new(id, id)
      end
    end

    alias_method :min, :first
    alias_method :max, :last
  end
end
