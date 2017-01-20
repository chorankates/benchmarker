# oh ruby
class Bnchmrkr; end

# Bnchmrkr::Mark represents individual lambda runs within a Bnchmrkr run
class Bnchmrkr::Mark
  include Enumerable

  attr_reader :config, :mode_precision, :precision
  attr_reader :computed, :lambda, :name
  attr_reader :fastest, :slowest, :mean, :median, :mode, :total

  def initialize(name, lambda, config = {})
    @config    = config
    @name      = name
    @lambda    = lambda # TODO this name is going to cause problems
    @measures  = Array.new

    @mode_precision = @config[:mode_precision] # specifically for mode calculation
    @precision      = @config[:precision] # output and caching, really 'rounding'

    reset_computations # initialize to known values
  end

  # +measure+ Benchmark.measure{} result
  def add_measure(measure)
    @measures << measure
    reset_computations if @computed # as soon as a measure is added, previous computations are invalid
  end

  # allows Array-like behavior on the Array of measurements contained in a Bnchmrkr::Mark
  def each(&block)
    @measures.each(&block)
  end

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
    @mean    = sprintf('%%df', @precision, total / sorted.size).to_f
    @median  = sorted[(sorted.size / 2)]
    @mode    = mode
    @total   = sprintf('%%df', @precision, total).to_f

    @computed = true
  end

  # a semi-fancy and somewhat fragile inspect method
  ## try to compute if we haven't been, ensuring we always return a hash
  def inspect
    begin
      self.compute unless @computed
      {
        :name    => @name,
        :fastest => @fastest.real,
        :slowest => @slowest.real,
        :mean    => @mean,
        :median  => @median,
        :mode    => @mode,
        :total   => @total,
      }
    rescue => e
      { :name => @name, :computed => @computed }
    end
  end

  private

  # reset internal computed values, used when a new measure is added
  def reset_computations
    @computed = false
    @fastest  = :uncomputed
    @slowest  = :uncomputed
    @mean     = :uncomputed
    @median   = :uncomputed
    @mode     = :uncomputed
    @total    = :uncomputed
  end

end