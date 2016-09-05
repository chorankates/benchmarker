#!/usr/bin/ruby

require 'benchmark'

class Bnchmrkr; end # empty class to keep Ruby and my ordering preferences happy

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

# Bnchmrkr is a tool to help Benchmark.measure {} and compare different method implementations
class Bnchmrkr

  attr_reader :executions, :marks, :fastest, :slowest

  def initialize(lambdas, executions = 100)
    @executions  = executions
    @marks       = Hash.new

    @fastest = nil
    @slowest = nil

    lambdas.each_pair do |name, l|
      unless name.class.eql?(Symbol) and l.class.eql?(Proc)
        raise ArgumentError.new(sprintf('expecting[Symbol,Proc], got[%s,%s]', name.class, l.class))
      end

      @marks[name] = Bnchmrkr::Mark.new(name, l)
    end

    raise ArgumentError.new(sprintf('expecting[Fixnum], got[%s]', executions.class)) unless executions.class.eql?(Fixnum)

  end

  # return list of named Bnchmrkr::Marks
  def types
    @marks.keys
  end

  # 10 lines to actually do the work..
  def benchmark!
    @marks.each_pair do |_name, mark|
      1.upto(@executions).each do |_execution|
        measure = Benchmark.measure { mark.lambda.call }
        mark.add_measure(measure)
      end

      mark.compute # this is a safer place to do it than by computing on each measure, but still should consider putting this behind a flag
    end

    calculate_overall
  end

  def inspect
    return {:foo => { :bar => 'baz'}} if @fastest.nil?
    {
      :fastest => {
        :name    => @fastest.name,
        :fastest => @fastest.fastest.to_s.chomp,
        :by      => self.faster_by_result(@fastest.fastest, @slowest.slowest),
      },
      :slowest => {
        :name    => @slowest.name,
        :slowest => @slowest.fastest.to_s.chomp,
      },
      :meta => {
        :marks      => @marks.keys,
        :executions => @executions,
      },
    }
  end

  # overly intricate output formatting of overall and specific results
  def to_s
    string     = String.new
    inspection = self.inspect

    longest_key = inspection.keys.each { |i| i.length }.max.length + 5

    inspection.keys.each do |i|
      string << sprintf('%s:%s', i, "\n")
      inspection[i].keys.each do |k|
        string << sprintf("  %#{longest_key}s => %s%s", k, inspection[i][k], "\n")
      end
    end

    string
  end

  # +type+ name of a lambda that is known
  # find and return the fastest Bnchrmrkr::Mark per lambda of +type+
  def fastest_by_type(type)
    return nil unless @marks.has_key?(type)
    @marks[type].fastest
  end

  # +type+ name of a lambda that is known
  # find and return the slowest Bnchrmrkr::Mark per lambda of +type+
  def slowest_by_type(type)
    return nil unless @marks.has_key?(type)
    @marks[type].slowest
  end

  # find and return the fastest overall execution (regardless of lambda type)
  def fastest_overall
    calculate_overall
    @fastest
  end

  # find and return the slowest overall execution (regardless of lambda type)
  def slowest_overall
    calculate_overall
    @slowest
  end

  # +a+ Symbol that represents a known lambda
  # +b+ Symbol that represents a known lambda
  # +mode+ :fastest, :slowest, :mean, :median, :total
  # return boolean if a is faster than b, false if invalid
  def is_faster?(a, b, mode = :total)
    return false unless @marks.has_key?(a) and @marks.has_key?(b)
    # TODO not sure that we're doing the right thing here.. the fastest fast run should always be faster than the slowest slow run.. but should we be comparing fastest fast with slowest fast?
    @marks[a].fastest.__send__(mode) < @marks[b].fastest.__send__(mode)
  end

  # +a+ Bnchmrkr::Mark
  # +b+ Bnchmrlr::Mark
  # +mode+ :fastest, :slowest, :mean, :median, :total
  # return boolean if a is faster than b, false if invalid
  def is_slower?(a, b, mode = :total)
    ! is_faster?(a, b, mode)
  end

  # +a+ Bnchmrkr::Mark
  # +b+ Bnchmrkr::Mark
  # +percent+ Boolean representing percent (String) or Float difference
  # return Float representing difference in measures, or false, if b is slower than a
  def faster_by_result(a, b, percent = true, mode = :real)
    measure_a = a.__send__(mode)
    measure_b = b.__send__(mode)

    return false if measure_b < measure_a

    faster = (measure_b - measure_a) / measure_a
    percent ? sprintf('%4f%', faster * 100) : faster
  end

  # +a+ Symbol representing name of known lambda type
  # +b+ Symbol representing name of known lambda type
  # +percent+ Boolean representing percent (String) or Float difference
  # return Float representing difference in measures, or false, if b is slower than a
  def faster_by_type(a, b, percent = true, mode = :real)
    fastest_a = fastest_by_type(a).__send__(mode)
    fastest_b = fastest_by_type(b).__send__(mode)

    return false if fastest_b < fastest_a

    faster = (fastest_b - fastest_a) / fastest_a
    percent ? sprintf('%4f%', faster * 100) : faster
  end

  def slower_by_type(a, b, percent = true)
    ! faster_by_type(a, b, percent)
  end

  def slower_by_result(a, b, percent = true)
    ! faster_by_result(a, b, percent)
  end

  private

  # update fastest/slowest, return in a named Hash
  def calculate_overall(mode = :real)

    @marks.each_pair do |_name, mark|
      if @fastest.nil? or mark.fastest.__send__(mode) < @fastest.fastest.__send__(mode)
        @fastest = mark
      end

      if @slowest.nil? or mark.slowest.__send__(mode) > @slowest.slowest.__send__(mode)
        @slowest = mark
      end


    end

    p = {
      :fastest => @fastest,
      :slowest => @slowest,
      :faster_by => self.faster_by_result(@fastest.fastest, @slowest.slowest)
    }
    return p
  end

end
