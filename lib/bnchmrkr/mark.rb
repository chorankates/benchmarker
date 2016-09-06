# oh ruby
class Bnchmrkr; end

# Bnchmrkr::Mark represents individual lambda runs within a Bnchmrkr run
class Bnchmrkr::Mark
  include Enumerable

  attr_reader :computed, :lambda, :name, :mode_precision
  attr_reader :fastest, :slowest, :mean, :median, :mode, :total

  def initialize(name, lambda, mode_precision = 0)
    @name      = name
    @lambda    = lambda # TODO this name is going to cause problems
    @measures  = Array.new
    @computed  = false

    @mode_precision = mode_precision
  end

  # +measure+ Benchmark.measure{} result
  def add_measure(measure)
    @measures << measure
  end

  # allows Array-like behavior on the Array of measurements contained in a Bnchmrkr::Mark
  def each(&block)
    @measures.each(&block)
  end

  # generate (and TODO cache) results of computations
  def compute
    frequency_hash = Hash.new(0)
    total          = 0

    sorted = @measures.sort { |a,b| a.real <=> b.real }

    @measures.each do |measure|
      operand = @mode_precision.equal?(0) ? measure.real : measure.real.round(@mode_precision)
      frequency_hash[operand] += 1
    end

    max_frequency  = frequency_hash.values.max
    mode_candidate = frequency_hash.select{ |_operand, frequency| frequency.equal?(max_frequency) }.keys

    if max_frequency.equal?(1)
      mode = nil
    else
      mode = mode_candidate.size > 1 ? mode_candidate : mode_candidate.first
    end

    sorted.collect { |r| total += r.real }
    @fastest = sorted.first
    @slowest = sorted.last
    @mean    = sprintf('%5f', total / sorted.size).to_f
    @median  = sorted[(sorted.size / 2)]
    @mode    = mode
    @total   = sprintf('%5f', total).to_f

    @computed = true
  end

  # a semi-fancy and somewhat fragile inspect method
  ## try to compute if we haven't been, ensuring we always return a hash
  def inspect
    begin
      self.compute unless @computed
      {
        :fastest => @fastest.real,
        :slowest => @slowest.real,
        :mean    => @mean,
        :median  => @median,
        :mode    => @mode,
        :total   => @total,
      }
    rescue => e
      { }
    end
  end

end