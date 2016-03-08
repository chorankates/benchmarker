require_relative File.expand_path(sprintf('%s/../../lib/bnchmrkr', File.dirname(__FILE__)))
require 'test-unit'

# tests for the example in examplescontrived.rb
class TestContrived < Test::Unit::TestCase

  def setup
    @tester = Bnchmrkr.new({
      :count_to_1k   => lambda { 1.upto(1000).each   { |i| i } },
      :count_to_5k   => lambda { 1.upto(5000).each   { |i| i } },
      :count_to_10k  => lambda { 1.upto(10000).each  { |i| i } },
      :count_to_50k  => lambda { 1.upto(50000).each  { |i| i } },
      :count_to_100k => lambda { 1.upto(100000).each { |i| i } },
    }, 10)

    @tester.benchmark!
  end

  def test_fastest
    assert_equal(:count_to_1k, @tester.fastest_overall[:name])
    assert_true(@tester.fastest_overall[:measure] < @tester.slowest_overall[:measure])
  end

  def test_slowest
    slowest_overall = @tester.slowest_overall
    fastest_overall = @tester.fastest_overall

    assert_equal(:count_to_100k, slowest_overall[:name])
    assert_true(slowest_overall[:measure] > fastest_overall[:measure])
  end

  def test_speed_by_type
    @tester.types.each do |type|
      slowest = @tester.slowest_by_type(type)
      fastest = @tester.fastest_by_type(type)

      assert_true(slowest > fastest)
    end
  end

  def test_is_faster?
    fast = @tester.fastest_overall[:name]
    slow = @tester.slowest_overall[:name]

    forward = @tester.is_faster?(fast, slow)
    reverse = @tester.is_faster?(slow, fast)
    equal   = @tester.is_faster?(fast, fast)

    assert_not_equal(forward, reverse)
    assert_true(forward)
    assert_false(reverse)
    assert_false(equal)
  end

  def test_is_slower?
    fast = @tester.fastest_overall[:name]
    slow = @tester.slowest_overall[:name]

    forward = @tester.is_slower?(slow, fast)
    reverse = @tester.is_slower?(fast, slow)
    equal   = @tester.is_slower?(slow, slow)

    assert_not_equal(forward, reverse)
    assert_true(forward)
    assert_false(reverse)
    assert_true(equal) # ugh, this is misleading.. but is_slower? is boolean opposite of is_slower?
  end

  def test_faster_by_result
    fast = @tester.fastest_overall
    slow = @tester.slowest_overall

    assert_not_nil(@tester.faster_by_result(fast, slow, true))
    assert_match(/\d+\.\d+%/, @tester.faster_by_result(fast, slow, true))
    assert_true(@tester.faster_by_result(fast, slow, false).is_a?(Float))
    assert_false(@tester.faster_by_result(slow, fast))
  end

  def test_faster_by_type
    fastest = @tester.fastest_overall[:name]
    slowest = @tester.slowest_overall[:name]

    assert_not_nil(@tester.faster_by_type(fastest, slowest, true))
    assert_match(/\d+\.\d+%/, @tester.faster_by_type(fastest, slowest, true))
    assert_true(@tester.faster_by_type(fastest, slowest, false).is_a?(Float))
    assert_false(@tester.faster_by_type(slowest, fastest))

  end

end