# coding: utf-8
# Test for belgium_2050_model_result
require 'rubygems'
gem 'minitest'
require 'test/unit'
require_relative '../lib/belgium_2050_model'
require 'pp'

class TestBelgium2050ModelResult < Test::Unit::TestCase

  def test_results
    @model = Belgium2050ModelResult.new
    tests_folder = File.join(File.dirname(__FILE__),"expected_results")
    Dir[File.join(tests_folder, "*.json")].each do |test|
      expected = IO.readlines(test)
      pathway = expected.shift
      expected = expected.join
      puts "Testing #{pathway}"
      @model.reset
      result = @model.calculate_pathway(pathway).pretty_inspect
      if result != expected
        File.open(test+".actual",'w') do |f|
          f.puts pathway
          f.puts result
        end
      end
      assert_equal expected, result
    end
  end
end

    
