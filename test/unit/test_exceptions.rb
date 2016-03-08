require_relative File.expand_path(sprintf('%s/../../lib/bnchmrkr', File.dirname(__FILE__)))
require 'test-unit'

class TestExceptions < Test::Unit::TestCase

  def setup; end

  def test_lambdas_will_raise
    tester = Bnchmrkr.new({
      :divbyzero => lambda {
        10 / 0
      },
    })

    assert_nothing_raised do
      tester.benchmark!
      puts tester

      assert_true(tester.results.has_key?('divbyzero-failed'.to_sym))
    end
  end

  def test_lambdas_wont_raise_anyway
    tester = Bnchmrkr.new({
      :foo => lambda { 'bar' }
    })

    assert_nothing_raised do
      tester.benchmark!
      puts tester

      assert_true(tester.results.has_key?(:foo))
    end

  end


end