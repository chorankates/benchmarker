#!/usr/bin/ruby

require 'benchmark'

class Benchmarker

  attr_reader :count, :results

  def initialize(lambdas, count = 100)

    @count   = count
    @results = Hash.new
    @lambdas = lambdas

    @fastest = { :name => :unknown, :measure => 2 ** 10 }
    @slowest = { :name => :unknown, :measure => 0 }

    @lambdas.each_pair do |name, l|
      unless name.class.eql?(Symbol) and l.class.eql?(Proc)
        raise ArgumentError.new(sprintf('expecting[Symbol,Proc], got[%s,%s]', name.class, l.class))
      end
    end

    raise ArgumentError.new(sprintf('expecting[Fixnum], got[%s]', count.class)) unless count.class.eql?(Fixnum)

  end

  def types
    @lambdas.keys
  end

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

  def inspect
    ## fastest, slowest, median, mode, total per lambda
    ## fastest, slowest for all (do average here too?)
    {
      :overall  => calculate_overall,
      :specific => calculate_per_lambda,
    }
  end

  def to_s
    string = ''
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

  def fastest_by_type(type)
    results = @results
    measures = Array.new

    return nil unless results.has_key?(type)
    results[type].collect { |r| measures << r.real}

    measures.sort.first
  end

  def fastest_overall
    calculate_overall
    @fastest
  end

  def slowest_by_type(type)
    results  = @results
    measures = Array.new

    return nil unless results.has_key?(type)
    results[type].collect { |r| measures << r.real }

    measures.sort.last
  end

  def slowest_overall
    calculate_overall
    @slowest
  end

  def is_faster?(a, b, mode = :total)
    result = calculate_per_lambda
    return false unless result.has_key?(a) and result.has_key?(b)
    result[a][mode] < result[b][mode]
  end

  def is_slower?(a,b)
    ! is_faster?(a,b)
  end

  private

  def add_measure(name, measure)
    self.results[name] = Array.new unless self.results.has_key?(name)
    self.results[name] << measure
  end

  # TODO come up with way to not recompute unless contents have changed
  def calculate_per_lambda
    hash = Hash.new

    # TODO percentage faster fastest is than slowest

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

  def calculate_overall

    hash = calculate_per_lambda

    hash.each_pair do |name,results|

      if results[:fastest] < @fastest[:measure]
        @fastest = { :name => name, :measure => results[:fastest] }
      end

      if results[:slowest] > @slowest[:measure]
        @slowest = { :name => name, :measure => results[:slowest] }
      end

    end

    {
      :fastest => @fastest,
      :slowest => @slowest,
    }
  end

end