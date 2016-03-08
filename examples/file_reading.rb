#
# line by line vs. .read and then split

require_relative File.expand_path(sprintf('%s/../lib/bnchmrkr', File.dirname(__FILE__)))

# exposes #read!, which slurps the file in and splits on spaces
class ReadAndSplit
  attr_reader :file

  def initialize(file)
    @file = file
  end

  def read!
    contents = File.read(@file).split("\n")
  end
end

# exposes #read!, which reads each line at a time into an array
class ReadAndIterate
  attr_reader :file

  def initialize(file)
    @file = file
  end

  def read!
    contents = Array.new
    f = File.new(file)
    f.each_line do |line|
      contents << line
    end
  end

end

def generate_ras_variances(files)
  hash = Hash.new
  name = :split
  files.each do |file|
    local_name = sprintf('%s_%s', name.to_s, File.basename(file)).to_sym
    hash[local_name] = lambda {
      brl = ReadAndSplit.new(file)
      brl.read!
    }
  end
  hash
end

def generate_rai_variances(files)
  hash = Hash.new
  name = :iterate
  files.each do |file|
    local_name = sprintf('%s_%s', name.to_s, File.basename(file)).to_sym
    hash[local_name] = lambda {
      rai = ReadAndIterate.new(file)
      rai.read!
    }
  end
  hash
end


files = [
  File.expand_path(sprintf('%s/../resources/li-100kw.txt', File.dirname(__FILE__))),
  File.expand_path(sprintf('%s/../resources/li-500kw.txt', File.dirname(__FILE__))),
  File.expand_path(sprintf('%s/../resources/li-1Mw.txt', File.dirname(__FILE__))),
  __FILE__,
]

tester = Bnchmrkr.new({
  :split => lambda {
    brl = ReadAndSplit.new(files.first)
    brl.read!
  },
  :iterate => lambda {
    rai = ReadAndIterate.new(files.first)
    rai.read!
  }
}, 500)

tester.benchmark!
puts tester

tester2 = Bnchmrkr.new(
  generate_rai_variances(files).merge(
    generate_ras_variances(files)),
  100)

tester2.benchmark!
puts tester2


