# benchmark ASCII math vs. array vs. hash lookup
require_relative File.expand_path(sprintf('%s/../lib/bnchmrkr', File.dirname(__FILE__)))

# contains the various implementations and maintains a helper
class Workers

  attr_accessor :ceiling, :helper, :results

  def initialize
    @ceiling = 10 # number of times to run each token through
    @helper  = Helpers.new
    @results = Hash.new
  end

  def self.ascii_math(token)
    value = 0.0
    token.each_byte do |chr_value|
      value += (chr_value - 97) # 97 is ASCII value for 'a'
    end

    value / 100.0
  end

  def array_index(token)
    value = 0.0
    token.each_byte do |chr_value|
      value += helper.array[chr_value]
    end

    value / 100.0
  end

  def hash_lookup(token)
    value = 0.0
    token.each_char do |chr|
      value += helper.hash[chr]
    end

    value / 100
  end

end

# populate helper data structs
class Helpers

  attr_accessor :array, :hash

  def initialize
    @array = Helpers.get_array
    @hash  = Helpers.get_hash
  end

  def self.get_array
    array = Array.new(0)
    i     = 1
    ('a'..'z').to_a.each do |chr|
      array[chr.ord] = i < 10 ? sprintf('0.0%d', i).to_f : sprintf('0.%d', i).to_f
      i += 1
    end

    array
  end

  def self.get_hash
    hash = Hash.new
    0.upto(26) do |i|
      value = i < 10 ? sprintf('0.0%d', i + 1) : sprintf('0.%d', i + 1)
      hash[(i + 97).chr] = value.to_f
    end

    hash
  end


end

# main()
if __FILE__ == $0

  lambdas = Hash.new
  worker  = Workers.new

  [
    File.expand_path(sprintf('%s/../resources/li-50kw.txt', File.dirname(__FILE__))),
    File.expand_path(sprintf('%s/../resources/li-100kw.txt', File.dirname(__FILE__))),
    #File.expand_path(sprintf('%s/../resources/li-500kw.txt', File.dirname(__FILE__))),
    __FILE__,
  ].each do |file|
    next unless File.file?(file)
    raw_content = File.read(file).split(/\s/)
    content = Array.new

    # clean it up so we only have lower case alpha
    raw_content.each do |raw|
      cleaned = raw.downcase.gsub(/[\W_\d]/, '')
      content << cleaned unless cleaned.eql?('')
    end

    lambdas[sprintf('ascii_math-%s',  File.basename(file)).to_sym] = lambda { content.each { |c| Workers.ascii_math(c) } }
    lambdas[sprintf('array_index-%s', File.basename(file)).to_sym] = lambda { content.each { |c| worker.array_index(c) } }
    lambdas[sprintf('hash_lookup-%s', File.basename(file)).to_sym] = lambda { content.each { |c| worker.hash_lookup(c) } }
  end


  tester = Bnchmrkr.new(lambdas, 10)
  tester.benchmark!
  puts tester

end