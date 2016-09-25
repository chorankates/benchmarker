require_relative File.expand_path(sprintf('%s/../../lib/bnchmrkr', File.dirname(__FILE__)))
require 'test-unit'


# test valid/invalid instantiations
class TestInitialize < Test::Unit::TestCase

  def setup; end

  def test_valid

    assert_nothing_raised do
      Bnchmrkr.new({:foo => lambda {}})
      Bnchmrkr.new({:bar => lambda {}}, 10)
      Bnchmrkr.new({:foo => lambda { 'foo' }, :bar => lambda { 'bar' } })
      Bnchmrkr.new({:bar => lambda { 'bar' }, :baz => lambda { 'baz' } })
      Bnchmrkr.new(:foo => lambda { 'fizz' }) # hipster formatting supported by default
    end

  end

  # TODO this is really testing Bnchmrkr::Mark objects
  def test_initial_values

    bnchmrkr = Bnchmrkr.new({:foo => lambda {}})

    bnchmrkr.marks.each_pair do |name, m|
      [ :fastest, :slowest, :mean, :median, :mode, :total ].each do |a|
        assert_equal(:uncomputed, m.__send__(a), sprintf('failed[%s] for[%s]', a, name))
      end
    end

  end

  def test_invalid

    # not a proc
    assert_raise ArgumentError do
      Bnchmrkr.new({:foo => :bar})
    end

    # one valid, one invalid
    assert_raise ArgumentError do
      Bnchmrkr.new({
        :foo => lambda { 'foo' },
        :bar => 'bar',
      })
    end

    # not a number
    assert_raise ArgumentError do
      Bnchmrkr.new({:foo => :bar}, 'foo')
    end

    # not a number pt 2
    assert_raise ArgumentError do
      Bnchmrkr.new({:foo => :bar}, :foo)
    end

    # not a fixnum
    assert_raise ArgumentError do
      Bnchmrkr.new({:foo => :bar}, 1.1)
    end

  end

end