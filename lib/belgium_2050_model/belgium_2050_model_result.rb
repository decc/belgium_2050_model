require_relative '../belgium_2050_model'

class Belgium2050ModelResult < Belgium2050ModelUtilities  
  attr_accessor :excel, :pathway
  
  def initialize
    @excel = Belgium2050ModelShim.new
  end
  
  def self.calculate_pathway(code)
    new.calculate_pathway(code)
  end
  
  def calculate_pathway(code)
    Thread.exclusive do 
      reset
      @pathway = { _id: code, choices: set_choices(code) }
      primary_energy_tables
    end
    return pathway
  end
      
  def primary_energy_tables
    #pathway[:ghg] = table 182, 192
    #pathway[:final_energy_demand, ] = table 13, 18
    #pathway[:primary_energy_supply] = table 283, 296
    pathway[:ghg][:percent_reduction_from_1990] = (r("control_ad44") * 100).round
  end
  
  
  # Helper methods
  
  def table(start_row,end_row)
    t = {}
    (start_row..end_row).each do |row|
      t[label("intermediate_output",row)] = annual_data("intermediate_output",row)
    end
    t
  end
  
  def label(sheet,row)
    r("#{sheet}_d#{row}").to_s
  end
  
  def annual_data(sheet,row)
    ['az','ba','bb','bc','bd','be','bf','bg','bh'].map { |c| r("#{sheet}_#{c}#{row}") }
  end
  
  def sum(hash_a,hash_b)
    return nil unless hash_a && hash_b
    summed_hash = {}
    hash_a.each do |key,value|
      summed_hash[key] = value + hash_b[key]
    end
    return summed_hash
  end
  
end

if __FILE__ == $0
  g = Belgium2050ModelResult.new

  tests = 100
  t = Time.now
  a = []
  tests.times do
    c = Belgium2050ModelResult::CONTROL.map { rand(4)+1 }.join
    p c
    a << r = g.calculate_pathway(c)
    p r
  end
  te = Time.now - t
  puts "#{te/tests} seconds per run"
  puts "#{tests/te} runs per second"
end
