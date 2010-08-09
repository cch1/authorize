require 'set'

class Authorize::Bitmask < Set
  include Comparable

  class << self
    attr_reader :name_values
    def new(fixnum_or_enum = Set.new)
      enum = fixnum_or_enum.kind_of?(Fixnum) ? enum(fixnum_or_enum) : fixnum_or_enum
      super(enum)
    end

    # Record bit names and define dynamic methods
    def name_values=(h)
      h.each do |n, v|
        define_method("_#{n}") {include?(n) ? true : false}
        define_method("_#{n}=") {|v| v ? self.add(n) : self.delete(n)}
        alias_method "_#{n}?", "_#{n}"
      end
      @name_values = h
    end

    # The maximum value this bitmask can hold (in which every named bit is set).
    def max
      name_values.values.inject{|memo, v| memo | v}
    end

    # Enumerates all operations included in the given mask
    def enum(mask)
      raise RangeError, "Unnamed bits in mask (#{mask.to_s(2)})" unless (mask | max) == max
      name_values.inject(Set[]){|s, (p, v)| s << p if (v == (mask & v)); s }
    end
  end

  def add(el)
    raise ArgumentError, "Unrecognized bit name" unless self.class.name_values.keys.include?(el)
    super
  end
  alias << add

  # Calculate the integer value for the mask
  def to_i
    inject(0) {|memo, n| memo | self.class.name_values[n]}
  end
  alias to_int to_i

  def valid?
    inject(true) {|memo, n| memo && !!self.class.name_values[n]}
  end

  # Return an equivalent Bitmask using only fundamental names, never aggregate names
  def fundamental
    complete.to_canonical_array.inject(self.class.new) do |memo, n|
      memo << n unless (memo.to_i & self.class.name_values[n]) == self.class.name_values[n]
      memo
    end
  end

  # Return an equivalent Bitmask using aggregated names to replace fundamental names where possible
  def minimal
    complete.to_canonical_array.reverse.inject(self.class.new) do |memo, n|
      memo << n unless (memo.to_i & self.class.name_values[n]) == self.class.name_values[n]
      memo
    end
  end

  # Return an equivalent Bitmask using all possible names (fundamental and aggregate)
  def complete
    self.class.new(to_int)
  end

  # Comparability derives from integer representation
  def <=>(other)
    to_int <=> other.to_int
  end

  def to_s
    to_canonical_array.join(" | ")
  end

  def to_canonical_array
    sort_by{|name| self.class.name_values[name]}
  end
end