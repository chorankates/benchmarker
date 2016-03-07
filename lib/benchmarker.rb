#!/usr/bin/ruby

require 'benchmark'

class Benchmarker

  attr_reader :count, :results

  def initialize(lambdas, count = 100)

    @count   = count
    @results = Hash.new
    @lambdas = lambdas # TODO input validation

    @lambdas.each_pair do |name, l|
      unless name.class.eql?(Symbol) and l.class.eql?(Proc)
        raise StandardError.new(sprintf('expecting[Symbol,Proc], got[%s,%s]', name.class, l.class))
      end
    end

    #
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
    calculate
  end

  def to_s
    string = ''
    inspection = self.inspect
    return string unless inspection.nil? or inspection.has_key?(:overall)
    longest_key = 20 # TODO determine this dynamically

    inspection[:overall].keys.sort.each do |key|
      string << sprintf("  %#{longest_key}s => %s%s", key, inspection[:overall][key], "\n")
    end

    string
  end

  private

  def add_measure(name, measure)
    self.results[name] = Array.new unless self.results.has_key?(name)
    self.results[name] << measure
  end

  def calculate
    hash = Hash.new

    # TODO percentage faster fastest is than slowest

    # determine per lambda results
    @results.each_pair do |name, measures|
      sorted = measures.sort { |a,b| a.real <=> b.real }

      hash[name] = Hash.new

      total = 0
      measures.collect {|m| total += m.real }

      # TODO do we want to determine the mode?
      hash[name][:fastest] = sorted.first.real
      hash[name][:slowest] = sorted.last.real
      hash[name][:mean]    = total / sorted.size
      hash[name][:median]  = sorted[(sorted.size / 2)].real
      hash[name][:total]   = total
    end


    # determine overall results
    hash[:overall] = {
      :fastest => 2 ** 10,
      :slowest => 0,
    }

    hash.each_pair do |name,results|
      next if name.eql?(:overall)

      if results[:fastest] < hash[:overall][:fastest]
        hash[:overall][:fastest] = results[:fastest]
        hash[:overall][:fastest_name] = name
      end

      if results[:slowest] > hash[:overall][:slowest]
        hash[:overall][:slowest] = results[:slowest]
        hash[:overall][:slowest_name] = name
      end

      # if results[:total] < hash[:overall][:overall_fastest]
      #   hash[:overall][:overall_fastest] = results[:total]
      #   hash[:overall][:overall_fastest_name] = name
      # end

    end

    #faster_pct = (((hash[:overall][:slowest] - hash[:overall][:fastest]) / hash[:overall][:slowest]) * 100)

    #p 'DBGZ' if nil?
  end

end