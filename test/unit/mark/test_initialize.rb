require_relative File.expand_path(sprintf('%s/../../helper', File.dirname(__FILE__)))

class TestMarkInitialize < Test::Unit::TestCase

  def setup
    @bnchmrkr = Bnchmrkr.new({:foo => lambda {}})
  end

  def test_initial_values

    @bnchmrkr.marks.each_pair do |name, m|
      [ :fastest, :slowest, :mean, :median, :mode, :total ].each do |a|
        assert_equal(:uncomputed, m.__send__(a), sprintf('failed[%s] for[%s]', a, name))
      end
    end

  end

end