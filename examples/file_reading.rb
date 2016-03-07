#
# line by line vs. .read and then iterate
# with a varying array of files

require_relative '../lib/benchmarker'

class ReadByLine
  attr_reader :files

  def initialize(files)
    @files = files
  end

  def read!
    @files.each do |file|
      contents = File.read(file).split("\n")
    end
  end
end

class ReadAndIterate
  attr_reader :files

  def initialize(files)
    @files = files
  end

  def read!
    @files.each do |file|
      contents = Array.new
      f = File.new(file)
      f.each_line do |line|
        contents << line
      end
    end
  end

end

@files = [
  File.expand_path(sprintf('%s/../resources/li-1kw.txt', File.dirname(__FILE__))),
  File.expand_path(sprintf('%s/../resources/li-10kw.txt', File.dirname(__FILE__))),
  File.expand_path(sprintf('%s/../resources/li-50kw.txt', File.dirname(__FILE__))),
  File.expand_path(sprintf('%s/../resources/li-100kw.txt', File.dirname(__FILE__))),
]

tester = Benchmarker.new({
  :byline => lambda {
    brl = ReadByLine.new(@files)
    brl.read!
  },
  :iterate => lambda {
    rai = ReadAndIterate.new(@files)
    rai.read!
  }
})

tester.benchmark!
puts tester

