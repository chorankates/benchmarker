require_relative File.expand_path(sprintf('%s/../../lib/bnchmrkr', File.dirname(__FILE__)))
require 'test-unit'

# run all examples, ensure non-0 exit code and non-nil output
class TestExamples < Test::Unit::TestCase

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