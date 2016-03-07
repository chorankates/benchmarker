#!/usr/bin/ruby
# contrived.rb - methods that intentionally take differing amounts of time

require_relative '../lib/benchmarker'

tester = Benchmarker.new({
  :count_to_1k   => lambda { 1.upto(1000).each   { |i| i } },
  :count_to_5k   => lambda { 1.upto(5000).each   { |i| i } },
  :count_to_10k  => lambda { 1.upto(10000).each  { |i| i } },
  :count_to_50k  => lambda { 1.upto(50000).each  { |i| i } },
  :count_to_100k => lambda { 1.upto(100000).each { |i| i } },
}, 1000)

tester.benchmark!

puts tester
