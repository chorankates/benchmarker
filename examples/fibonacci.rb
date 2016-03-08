#!/usr/bin/ruby
# fibonacci.rb - comparing recursive vs. iterative functions

require_relative File.expand_path(sprintf('%s/../lib/benchmarker', File.dirname(__FILE__)))

require 'test-unit'

def recursive(n)
  if n <= 1
    return n
  end

  ( recursive(n - 1) + recursive(n - 2) )
end

def iterative(target)

  if target <= 1
    return target
  end

  hash = {
    0 => 0,
    1 => 1,
  }

  2.upto(target).each do |e|
    hash[e] = (hash[e - 1] + hash[e - 2])
  end

  hash[target]
end

class TestFibonacci < Test::Unit::TestCase

  def test_fibonacci_equality

    1.upto(25).each do |i|
      recursive_result = recursive(i)
      iterative_result = iterative(i)
      assert_equal(recursive_result, iterative_result)
    end

  end

  def test_fibonacci_speed

    tester = Benchmarker.new({
      :iterative => lambda { iterative(30) },
      :recursive => lambda { recursive(30) },
    }, 25)

    tester.benchmark!
    puts tester

    assert_true(tester.is_faster?(:iterative, :recursive))
    assert_true(tester.is_slower?(:recursive, :iterative))
    assert_equal(:iterative, tester.fastest_overall[:name])
    assert_equal(:recursive, tester.slowest_overall[:name])

  end

end