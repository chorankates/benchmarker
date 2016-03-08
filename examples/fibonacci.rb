#!/usr/bin/ruby
# fibonacci.rb - comparing recursive vs. iterative functions

require_relative '../lib/benchmarker'
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
      :iterative  => lambda { iterative(20) },
      :rescursive => lambda { recursive(20) },
    })

    tester.benchmark!

    assert_true(tester.is_faster?(:recursive, :iterative))
    assert_true(tester.is_slower?(:iterative, :recursive))
    assert_equal(:recursive, tester.fastest_overall)
    assert_equal(:iterative, tester.slowest_overall)

  end

end