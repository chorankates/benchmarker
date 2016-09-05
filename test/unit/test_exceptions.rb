require_relative File.expand_path(sprintf('%s/../../lib/bnchmrkr', File.dirname(__FILE__)))
require 'test-unit'

# test that exceptions thrown in the middle of a #benchmark! run will behave in expected ways
class TestExceptions < Test::Unit::TestCase

  def setup; end

  def test_lambdas_will_raise # but we will catch them
    symbol = :divbyzero

    tester = Bnchmrkr.new({
      symbol => lambda {
        10 / 0
      },
    })

    e = assert_raise do
      tester.benchmark!
    end

    assert_true(tester.marks.has_key?(symbol))
    assert_equal(ZeroDivisionError, e.class)
  end

  def test_lambdas_wont_raise_anyway
    tester = Bnchmrkr.new({
      :foo => lambda { 'bar' }
    })

    assert_nothing_raised do
      tester.benchmark!
      assert_true(tester.marks.has_key?(:foo))
    end

  end


end