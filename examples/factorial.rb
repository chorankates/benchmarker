#!/usr/bin/env ruby
## factorial.rb

require_relative File.expand_path(sprintf('%s/bnchmrkr/lib/bnchmrkr', File.dirname(__FILE__)))

target = 50_000

tester = Bnchmrkr.new({
  :recursive => lambda { (1..target).inject(:*) },
  :iterative => lambda {
    bases = Hash.new
    (1..target).collect do |i|
      i * (i - 1) || 1
    end
  },
})

tester.benchmark!

puts tester
