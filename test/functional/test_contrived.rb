require_relative File.expand_path(sprintf('%s/../helper', File.dirname(__FILE__)))

class TestFunctionalContrived < Test::Unit::TestCase

  def setup
    # TODO we really only want to do this on _startup_, not _setup_
    @tester = Bnchmrkr.new({
      :count_to_1k   => lambda { 1.upto(1000).each   { |i| i } },
      :count_to_5k   => lambda { 1.upto(5000).each   { |i| i } },
      :count_to_10k  => lambda { 1.upto(10000).each  { |i| i } },
      :count_to_50k  => lambda { 1.upto(50000).each  { |i| i } },
      :count_to_100k => lambda { 1.upto(100000).each { |i| i } },
    }, 10)

    assert_nothing_raised do
      @tester.benchmark!
    end
  end

  def test_fastest
    assert_equal(:count_to_1k, @tester.fastest_overall.name)
    assert_true(@tester.fastest_overall.fastest.real < @tester.slowest_overall.slowest.real)
  end

  def test_slowest
    slowest_overall = @tester.slowest_overall
    fastest_overall = @tester.fastest_overall

    generic_failure_message = sprintf('fast[%s] slow[%s]', fastest_overall, slowest_overall)

    assert_equal(:count_to_100k, slowest_overall.name, generic_failure_message)
    assert_true(slowest_overall.slowest.real > fastest_overall.fastest.real, generic_failure_message)
  end

  def test_speed_by_type
    @tester.types.each do |type|
      slowest = @tester.slowest_by_type(type).real
      fastest = @tester.fastest_by_type(type).real

      generic_failure_message = sprintf('fast[%s] slow[%s]', fastest, slowest)

      assert_true(slowest > fastest, generic_failure_message)
    end
  end

  def test_is_faster?
    fast = @tester.fastest_overall.name
    slow = @tester.slowest_overall.name

    generic_failure_message = sprintf('fast[%s] slow[%s]', fast, slow)

    forward = @tester.is_faster?(fast, slow)
    reverse = @tester.is_faster?(slow, fast)
    equal   = @tester.is_faster?(fast, fast)

    assert_not_equal(forward, reverse, generic_failure_message)
    assert_true(forward, generic_failure_message)
    assert_false(reverse, generic_failure_message)
    assert_false(equal, generic_failure_message)
  end

  def test_is_slower?
    fast = @tester.fastest_overall.name
    slow = @tester.slowest_overall.name

    generic_failure_message = sprintf('fast[%s] slow[%s]', fast, slow)

    forward = @tester.is_slower?(slow, fast)
    reverse = @tester.is_slower?(fast, slow)
    equal   = @tester.is_slower?(slow, slow)

    assert_not_equal(forward, reverse, generic_failure_message)
    assert_true(forward, generic_failure_message)
    assert_false(reverse, generic_failure_message)
    assert_true(equal, sprintf('fast[%s] slow[%s]', fast, slow))
  end

  def test_faster_by_result
    fast = @tester.fastest_overall.fastest
    slow = @tester.slowest_overall.slowest

    generic_failure_message = sprintf('fast[%s] slow[%s]', fast, slow)

    assert_not_nil(@tester.faster_by_result(fast, slow, true), generic_failure_message)
    assert_match(/\d+\.\d+%/, @tester.faster_by_result(fast, slow, true), generic_failure_message)
    assert_true(@tester.faster_by_result(fast, slow, false).is_a?(Float), generic_failure_message)
    assert_false(@tester.faster_by_result(slow, fast), generic_failure_message)
  end

  def test_faster_by_type
    fastest = @tester.fastest_overall.name
    slowest = @tester.slowest_overall.name

    generic_failure_message = sprintf('fast[%s] slow[%s]', fastest, slowest)

    assert_not_nil(@tester.faster_by_type(fastest, slowest, true), generic_failure_message)
    assert_match(/\d+\.\d+%/, @tester.faster_by_type(fastest, slowest, true), generic_failure_message)
    assert_true(@tester.faster_by_type(fastest, slowest, false).is_a?(Float), generic_failure_message)
    assert_false(@tester.faster_by_type(slowest, fastest), generic_failure_message)
  end

end

