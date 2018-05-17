#!/usr/bin/ruby
## log4r_vs_exception.rb
require_relative File.expand_path(sprintf('%s/../lib/bnchmrkr', File.dirname(__FILE__)))
require 'log4r'

$logger = Log4r::Logger.new('foo')
$logger.add(Log4r::Outputter.stderr) # this is a bit of a false equivalence, STDERR may be significantly faster or slower than postgres, depending on a lot of things
$logger.level = Log4r::WARN

tester = Bnchmrkr.new({
  :log4r      => lambda { $logger.debug('foo bar baz') },
  :exceptions => lambda {
    begin
      raise StandardError.new('foo bar baz')
    rescue => e
      sprintf('%s: %s', e.message, e.backtrace)
    end
  },
}, 300_000)

tester.benchmark!

puts tester
