require_relative File.expand_path(sprintf('%s/../../lib/bnchmrkr', File.dirname(__FILE__)))
require 'test-unit'

class TestContrived < Test::Unit::TestCase

  def setup;  end

  def test_all_examples
    @files = Dir.glob(sprintf('%s/../../examples/*.rb', File.dirname(__FILE__)))

    @files.each do |file|
      raw = `ruby #{file}`

      assert_true($?.success?)
      assert_not_nil(raw)
    end
  end

end