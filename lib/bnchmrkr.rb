#!/usr/bin/ruby

$LOAD_PATH << sprintf('%s/../lib', File.dirname(__FILE__))
require 'bnchmrkr/mark'

require 'benchmark'

# Bnchmrkr helps Benchmark.measure {} and compare different method implementations
class Bnchmrkr

  DEFAULT_EXECUTION_COUNT = 100
  UNCOMPUTED = :uncomputed

  attr_reader :executions, :marks, :fastest, :slowest

  def initialize(lambdas, executions = DEFAULT_EXECUTION_COUNT)
    @executions  = executions
    @marks       = Hash.new

    @fastest = UNCOMPUTED
    @slowest = UNCOMPUTED

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

  # < 10 lines to actually do the work..
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
    hash = Hash.new

    unless @fastest.nil? or @fastest.eql?(UNCOMPUTED)
      hash = {
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

    hash[:meta] = {
      :marks      => @marks.keys,
      :executions => @executions,
    }

    hash
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
  # +mode+ method to use on the Bnchmrkr::Mark object ot compare (:real, :cstime, :cutime, :stime, :utime, :total)
  # find and return the fastest Bnchrmrkr::Mark runtime per lambda of +type+
  def fastest_by_type(type, mode = :real)
    return UNCOMPUTED unless @marks.has_key?(type)
    @marks[type].fastest.__send__(mode)
  end

  # +type+ name of a lambda that is known
  # +mode+ method to use on the Bnchmrkr::Mark object ot compare (:real, :cstime, :cutime, :stime, :utime, :total)
  # find and return the slowest Bnchrmrkr::Mark runtime per lambda of +type+
  def slowest_by_type(type, mode = :real)
    return UNCOMPUTED unless @marks.has_key?(type)
    @marks[type].slowest.__send__(mode)
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
  def is_faster?(a, b, mode = :real)
    return false unless @marks.has_key?(a) and @marks.has_key?(b)
    # TODO not sure that we're doing the right thing here.. the fastest fast run should always be faster than the slowest slow run.. but should we be comparing fastest fast with slowest fast?
    @marks[a].fastest.__send__(mode) < @marks[b].fastest.__send__(mode)
  end

  # +a+ Bnchmrkr::Mark
  # +b+ Bnchmrkr::Mark
  # +mode+ :fastest, :slowest, :mean, :median, :total
  # return boolean if a is faster than b, false if invalid
  def is_slower?(a, b, mode = :real)
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

    reset_computation

    @marks.each_pair do |_name, mark|
      if @fastest.eql?(:uncomputed) or mark.fastest.__send__(mode) < @fastest.fastest.__send__(mode)
        @fastest = mark
      end

      if @slowest.eql?(:uncomputed) or mark.slowest.__send__(mode) > @slowest.slowest.__send__(mode)
        @slowest = mark
      end

    end

    {
      :fastest      => @fastest.fastest.__send__(mode),
      :fastest_name => @fastest.name,
      :slowest      => @slowest.slowest.__send__(mode),
      :slowest_name => @slowest.name,
      :faster_by    => self.faster_by_result(@fastest.fastest, @slowest.slowest)
    }
  end

  # helper method to reset internal state - but not sure we really need to be saving this in the first place..
  def reset_computation
    @fastest = UNCOMPUTED
    @slowest = UNCOMPUTED
  end

end
