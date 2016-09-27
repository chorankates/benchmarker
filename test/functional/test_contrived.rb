# TODO use a helper.rb
require_relative File.expand_path(sprintf('%s/../../lib/bnchmrkr', File.dirname(__FILE__)))
require 'test-unit'

class TestFunctionalContrived < Test::Unit::TestCase

  def setup
    # TODO we really only want to do this on _startup_, not _setup_
    @bnchmrkr = Bnchmrkr.new({
     :count_to_500 => lambda { 1.upto(500).each   { |i| i } },
     :count_to_1k  => lambda { 1.upto(1000).each   { |i| i } },
     :count_to_2k  => lambda { 1.upto(2000).each   { |i| i } },
    }, 10)
  end

  def test_functional_something

    assert_nothing_raised do
      @bnchmrkr.benchmark!
    end

    assert_not_nil(@bnchmrkr.fastest)
    assert_not_nil(@bnchmrkr.slowest)
    assert_true(@bnchmrkr.marks.size > 0)

    assert(@bnchmrkr.is_faster?(:count_to_500, :count_to_2k))
    assert(@bnchmrkr.is_slower?(:count_to_2k, :count_to_500))

    p 'DBGZ' if nil?
  end


end