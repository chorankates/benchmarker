require_relative File.expand_path(sprintf('%s/../../lib/benchmarker', File.dirname(__FILE__)))
require 'test-unit'

class TestInitialize < Test::Unit::TestCase

  def setup

  end

  def test_valid

    assert_nothing_raised do
      Benchmarker.new({:foo => lambda {}})
      Benchmarker.new({:bar => lambda {}}, 10)
      Benchmarker.new({:foo => lambda { 'foo' }, :bar => lambda { 'bar' } })
      Benchmarker.new({:bar => lambda { 'bar' }, :baz => lambda { 'baz' } })
      Benchmarker.new(:foo => lambda { 'fizz' }) # hipster formatting supported by default
    end

  end

  def test_invalid

    # not a proc
    assert_raise ArgumentError do
      Benchmarker.new({:foo => :bar})
    end

    # one valid, one invalid
    assert_raise ArgumentError do
      Benchmarker.new({
        :foo => lambda { 'foo' },
        :bar => 'bar',
      })
    end

    # not a number
    assert_raise ArgumentError do
      Benchmarker.new({:foo => :bar}, 'foo')
    end

    # not a number pt 2
    assert_raise ArgumentError do
      Benchmarker.new({:foo => :bar}, :foo)
    end

    # not a fixnum
    assert_raise ArgumentError do
      Benchmarker.new({:foo => :bar}, 1.1)
    end



  end

end