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
      # One method per view
      all_energy_tables
      electricity_tables
      energy_security_tables
      energy_flow_tables
      area_tables
      story_tables
      air_quality_tables # Not implemented
      costs_tables
    end
    return pathway
  end
      
  def all_energy_tables
    # Each number is a row on the CONTROL worksheet
    pathway[:ghg] = table 399, 400, 401, 402, 403, 404, 405, 406, 407, 409, 411, 412 
    pathway[:final_energy_demand, ] = table 12, 16, 19, 21
    pathway[:primary_energy_supply] = table 27, 28, 29, 30, 31, 32, 33, 34, 36, 41, 44, 48, 51, 52
  end

  def electricity_tables
  end

  def energy_security_tables
  end

  def energy_flow_tables
    # Not implemented
  end

  def area_tables
  end

  def story_tables
    #pathway[:ghg][:percent_reduction_from_1990] = (r("control_ae44") * 100).round
  end

  def air_quality_tables
    # Not implemented
  end

  def costs_tables
  end
  
  # Helper methods
 
  def table(*rows)
    t = {}
    rows.each do |row|
      t[label("output",row)] = annual_data("output",row)
    end
    t
  end
  
  def label(sheet,row)
    r("#{sheet}_e#{row}").to_s
  end
  
  def annual_data(sheet,row)
    ['ac','ad','ae','af','ag','ah','ai','aj','ak'].map { |c| r("#{sheet}_#{c}#{row}") }
  end
  
  def sum(hash_a,hash_b)
    return nil unless hash_a && hash_b
    summed_hash = {}
    hash_a.each do |key,value|
      summed_hash[key] = value + hash_b[key]
    end
    return summed_hash
  end
  
  # Set the 9 decimal points between 1.1 and 3.9
  FLOAT_TO_LETTER_MAP = Hash["abcdefghijklmnopqrstuvwxyzABCD".split('').map.with_index { |l,i| [(i/10.0)+1,l] }]
  FLOAT_TO_LETTER_MAP[0.0] = '0'
  FLOAT_TO_LETTER_MAP[1.0] = '1'
  FLOAT_TO_LETTER_MAP[2.0] = '2'
  FLOAT_TO_LETTER_MAP[3.0] = '3'
  FLOAT_TO_LETTER_MAP[4.0] = '4'
  
  LETTER_TO_FLOAT_MAP = FLOAT_TO_LETTER_MAP.invert
  
  # NB: The Belgian calcualtor has some inputs 10..40 rather than 1..4
  def convert_float_to_letters(array)
    array.map.with_index do |entry, i|
      type = ModelStructure.instance.types[i]
      entry = (entry / 10.0) if entry && type && type > 4
      case entry
      when Float; FLOAT_TO_LETTER_MAP[entry] || entry
      when nil; 0
      else entry
      end
    end
  end
  
  # NB: The Belgian calcualtor has some inputs 10..40 rather than 1..4
  # so adjust here. Also do maximum value check.
  def convert_letters_to_float(array)
    array.map.with_index do |entry,i|
      original = (LETTER_TO_FLOAT_MAP[entry].to_f || entry.to_f)
      type = ModelStructure.instance.types[i]
      if type == nil
        0
      elsif type < 10
        [original, type].min
      else
        [original * 10, type].min
      end
    end
  end
  
  CONTROL = (4..55).to_a.map { |r| "control_h#{r}"  } + (4..32).to_a.map { |r| "control_aa#{r}" }
  
  def set_choices(code)
    choices = code.split('')
    choices = convert_letters_to_float(choices)
    set_array(CONTROL,choices)
    choices
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
