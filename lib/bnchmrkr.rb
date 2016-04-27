#!/usr/bin/ruby

require 'benchmark'

# Bnchmrkr is a tool to help Benchmark.measure {} and compare different method implementations
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
        begin
          measure = Benchmark.measure {
            l.call
          }
          add_measure(name, measure)
        rescue => e
          add_measure(sprintf('%s-failed', name).to_sym, Benchmark.measure {})
        end
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

    longest_key = inspection[:specific].keys.each { |i| i.length }.max.length + 5

    inspection[:specific].keys.each do |i|
      string << sprintf('%s:%s', i, "\n")
      inspection[:specific][i].keys.sort.each do |k|
        string << sprintf("  %#{longest_key}s => %s%s", k, inspection[:specific][i][k], "\n")
      end
    end

    string << sprintf('overall:%s', "\n")
    inspection[:overall].each_pair do |type, measure|
      string << sprintf("  %#{longest_key}s => %s [%s]%s%s",
                        type,
                        measure[:name],
                        measure[:measure],
                        measure.has_key?(:faster_by) ? sprintf(' [faster by %s]', measure[:faster_by]) : '',
                        "\n"
      )
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

  # +a+ Symbol that represents a known lambda
  # +b+ Symbol that represents a known lambda
  # +mode+ :fastest, :slowest, :mean, :median, :total
  # return boolean if a is faster than b, false if invalid
  def is_faster?(a, b, mode = :total)
    result = calculate_per_lambda
    return false unless result.has_key?(a) and result.has_key?(b)
    result[a][mode] < result[b][mode]
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
  # +percent+ Boolean representing percent (String) or Float difference
  # return Float representing difference in measures, or false, if b is slower than a
  def faster_by_result(a, b, percent = true)
    return false if b[:measure] < a[:measure]

    faster = (b[:measure] - a[:measure]) / a[:measure]
    percent ? sprintf('%4f%', faster * 100) : faster
  end

  # +a+ Symbol representing name of known lambda type
  # +b+ Symbol representing name of known lambda type
  # +percent+ Boolean representing percent (String) or Float difference
  # return Float representing difference in measures, or false, if b is slower than a
  def faster_by_type(a, b, percent = true)
    fastest_a = fastest_by_type(a)
    fastest_b = fastest_by_type(b)

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

  def add_measure(name, measure)
    self.results[name] = Array.new unless self.results.has_key?(name)
    self.results[name] << measure
  end

  # +mode_precision+ Fixnum indicating number of digits to consider during mode calculation, default to 0, which will use all signal
  # from existing results, generate some statistics per lambda type
  def calculate_per_lambda(mode_precision = 0)
    hash = Hash.new

    # TODO come up with way to not recompute unless contents have changed -- https://github.com/chorankates/bnchmrkr/issues/3

    @results.each_pair do |name, measures|
      hash[name]     = Hash.new
      frequency_hash = Hash.new(0)
      total = 0

      sorted = measures.sort { |a,b| a.real <=> b.real }
      measures.each do |measure|
        operand = mode_precision.equal?(0) ? measure.real : measure.real.round(mode_precision)
        frequency_hash[operand] += 1
      end

      max_frequency = frequency_hash.values.max
      mode_candidate = frequency_hash.select{ |_operand, frequency| frequency.equal?(max_frequency) }.keys
      if max_frequency.equal?(1)
        mode = nil
      else
        mode = mode_candidate.size > 1 ? mode_candidate : mode_candidate.first
      end

      measures.collect {|m| total += m.real }
      hash[name][:fastest] = sorted.first.real
      hash[name][:slowest] = sorted.last.real
      hash[name][:mean]    = sprintf('%5f', total / sorted.size).to_f
      hash[name][:median]  = sorted[(sorted.size / 2)].real
      hash[name][:mode]    = mode
      hash[name][:total]   = sprintf('%5f', total).to_f
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

    @fastest[:faster_by] = self.faster_by_result(@fastest, @slowest)
    { :fastest => @fastest, :slowest => @slowest }
  end

end
