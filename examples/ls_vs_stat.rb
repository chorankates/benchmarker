#!/usr/bin/ruby
# ls_vs_stat.rb - comparing `ls <dir>/*` to `stat <dir>/*`

require_relative '../lib/benchmarker'

dir = File.dirname(__FILE__)
dir = sprintf('%s/*', ENV['HOME'])

ls = lambda {
  `ls #{dir}`
}

stat = lambda {
  `stat #{dir}`
}

tester = Benchmarker.new({
    :ls   => ls,
    :stat => stat,
  },
  10,
)

tester.benchmark!
#tester.inspect

puts tester