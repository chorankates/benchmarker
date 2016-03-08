#!/usr/bin/ruby

require 'benchmark'

class Bnchmrkr

  attr_reader :count, :results

  def initialize(lambdas, count = 100)

    @count    = count
    @results  = Hash.new
    @lambdas  = lambdas

    @fastest = { :name => :unknown, :measure => 2 ** 10 } # TODO really need to find a better max int
    @slowest = { :name => :unknown, :measure => 0 }

    @cache = Hash.new

    @lambdas.each_pair do |name, l|
      unless name.class.eql?(Symbol) and l.class.eql?(Proc)
        raise ArgumentError.new(sprintf('expecting[Symbol,Proc], got[%s,%s]', name.class, l.class))
      end
    end

    raise ArgumentError.new(sprintf('expecting[Fixnum], got[%s]', count.class)) unless count.class.eql?(Fixnum)

  end

  # return list of named lambdas known
  def types
    @lambdas.keys
  end

  # 10 lines to actually do the work..
  def benchmark!
    @lambdas.each_pair do |name, l|
      1.upto(@count).each do |round|
        measure = Benchmark.measure {
          l.call
        }
        add_measure(name, measure)
      end
    end

  end

  ## :specific => fastest, slowest, mean, median, total per lambda
  ## :overall  => fastest, slowest for all
  def inspect
    { :overall  => calculate_overall, :specific => calculate_per_lambda }
  end

  # overly intricate output formatting of overall and specific results
  def to_s
    string     = String.new
    inspection = self.inspect
    return string unless inspection.nil? or inspection.has_key?(:overall)
    longest_key = 15 # TODO determine this dynamically

    inspection[:specific].keys.each do |i|
      string << sprintf('%s:%s', i, "\n")
      inspection[:specific][i].keys.sort.each do |k|
        string << sprintf("  %#{longest_key}s => %s%s", k, inspection[:specific][i][k], "\n")
      end
    end

    string << sprintf('overall:%s', "\n")
    inspection[:overall].each_pair do |type, measure|
      string << sprintf("  %#{longest_key}s => %s [%s]%s", type, measure[:name], measure[:measure], "\n")
    end

    string
  end

  # +type+ name of a lambda that is known
  # find and return the fastest execution per lambda of +type+
  def fastest_by_type(type)
    results = @results
    measures = Array.new

    return nil unless results.has_key?(type)
    results[type].collect { |r| measures << r.real}

    measures.sort.first
  end

  # find and return the fastest overall execution (regardless of lambda type)
  def fastest_overall
    calculate_overall
    @fastest
  end

  # +type+ name of a lambda that is known
  # find and return the slowest execution per lambda of +type+
  def slowest_by_type(type)
    results  = @results
    measures = Array.new

    return nil unless results.has_key?(type)
    results[type].collect { |r| measures << r.real }

    measures.sort.last
  end

  # find and return the slowest overall execution (regardless of lambda type)
  def slowest_overall
    calculate_overall
    @slowest
  end

  # +a+ {:name => name, :measure => measure}
  # +b+ {:name => name, :measure => measure}
  # +mode+ :fastest, :slowest, :mean, :median, :total
  # return boolean if a is faster than b, false if invalid
  def is_faster?(a, b, mode = :total)
    result = calculate_per_lambda
    return false unless result.has_key?(a[:name]) and result.has_key?(b[:name])
    result[a[:name]][mode] < result[b[:name]][mode]
  end

  # +a+ {:name => name, :measure => measure}
  # +b+ {:name => name, :measure => measure}
  # +mode+ :fastest, :slowest, :mean, :median, :total
  # return boolean if a is faster than b, false if invalid
  def is_slower?(a, b, mode = :total)
    ! is_faster?(a, b, mode)
  end

  # +a+ {:name => name, :measure => measure}
  # +b+ {:name => name, :measure => measure}
  # return Float representing difference in measure, or false, if b is slower than a
  def faster_by(a, b, percent = true)
    return false if b[:measure] < a[:measure]

    faster = (b[:measure] - a[:measure]) / b[:measure]
    percent ? sprintf('%4f%', faster * 100) : faster
  end

  private

  def add_measure(name, measure)
    self.results[name] = Array.new unless self.results.has_key?(name)
    self.results[name] << measure
  end

  # from existing results, generate some statistics per lambda type
  def calculate_per_lambda
    hash = Hash.new

    # TODO come up with way to not recompute unless contents have changed

    @results.each_pair do |name, measures|
      sorted = measures.sort { |a,b| a.real <=> b.real }

      hash[name] = Hash.new

      total = 0
      measures.collect {|m| total += m.real }

      # TODO do we want to determine the mode?
      hash[name][:fastest] = sorted.first.real
      hash[name][:slowest] = sorted.last.real
      hash[name][:mean]    = sprintf('%5f', total / sorted.size)
      hash[name][:median]  = sorted[(sorted.size / 2)].real
      hash[name][:total]   = sprintf('%5f', total)
    end

    hash
  end

  # update fastest/slowest, return in a named Hash
  def calculate_overall
    calculate_per_lambda.each_pair do |name,results|
      if results[:fastest] < @fastest[:measure]
        @fastest = { :name => name, :measure => results[:fastest] }
      end

      if results[:slowest] > @slowest[:measure]
        @slowest = { :name => name, :measure => results[:slowest] }
      end
    end

    { :fastest => @fastest, :slowest => @slowest }
  end

end