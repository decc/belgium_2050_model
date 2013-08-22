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
      simple_costs_tables
      complex_costs_tables
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
    e = {}
    # Each number is a row on the CONTROL worksheet
    e[:emissions] = table 441, 442, 443, 444
    e[:demand] = table 94, 97, 110, 120
    e[:supply] = table 130, 131, 135, 136, 137, 138, 139, 141, 142, 143, 146, 149, 151
    pathway[:electricity] = e
  end

  def energy_security_tables
    energy_imports
    energy_diversity
  end

  def energy_imports
    sheet_name = "Online Graphs and Color codes"
    i = {}
    (189..195).each do |row|
      i[r("#{sheet_name}_b#{row}")] = {
        '2010' => {
          :quanitity => r("#{sheet_name}_d#{row}").to_f,
          :proportion => r("#{sheet_name}_e#{row}").to_f
        },
        '2050' => {
          :quanitity => r("#{sheet_name}_g#{row}").to_f,
          :proportion => r("#{sheet_name}_h#{row}").to_f
        }
      }
    end
    pathway['imports'] = i
  end

  def energy_diversity
    sheet_name = "Online Graphs and Color codes"
    i = {}
    (202..212).each do |row|
      i[r("#{sheet_name}_b#{row}")] = {
        '2010' => "#{(r("#{sheet_name}_d#{row}").to_f*100).round}%",
        '2050' => "#{(r("#{sheet_name}_g#{row}").to_f*100).round}%"
      }
    end
    pathway['diversity'] = i
  end

  def energy_flow_tables
    s = [] 
    (6..93).each do |row|
      s << [r("flows_c#{row}"),r("flows_m#{row}"),r("flows_d#{row}")]
    end
    pathway[:sankey] = s
  end

  def area_tables
    m = {}
    [6..11,15..18,22..22,27..27,31..36].each do |range|
      range.to_a.each do |row|
        m[r("land_use_d#{row}")] = r("land_use_p#{row}")
      end
    end
    pathway['map'] = m
  end

  def story_tables
    # Nothing additional neaded?
    #pathway[:ghg][:percent_reduction_from_1990] = (r("control_ae44") * 100).round
  end

  def air_quality_tables
    # Not implemented
  end

  def simple_costs_tables
    c = {}
    c[:sector] = table 492, 497, 502, 507
    c[:type] = table 509, 510, 511
    pathway[:simple_costs] = c
  end

  def complex_costs_tables
    t = {}
    low_start_row = 3
    point_start_row = 57
    high_start_row = 112
    number_of_components = 49
    
    # Normal cost components
    (0..number_of_components).to_a.each do |i|
            
      name          = r("costpercapita_b#{low_start_row+i}")
      
      low           = r("costpercapita_as#{low_start_row+i}")
      point         = r("costpercapita_as#{point_start_row+i}")
      high          = r("costpercapita_as#{high_start_row+i}")
      range         = high - low
      
      finance_low   = 0 # r("costpercapita_cp{low_start_row+i}") # Bodge for the zero interest rate at low
      finance_point = r("costpercapita_cp#{point_start_row+i}")
      finance_high  = r("costpercapita_cp#{high_start_row+i}")
      finance_range = finance_high - finance_low
      
      costs = {low:low,point:point,high:high,range:range,finance_low:finance_low,finance_point:finance_point,finance_high:finance_high,finance_range:finance_range}
      if t.has_key?(name)
        t[name] = sum(t[name],costs)
      else
        t[name] = costs
      end
    end
    
    # Merge some of the points
    t['Coal'] = sum(t['Indigenous fossil-fuel production - Coal'],t['Balancing imports - Coal'])
    t.delete 'Indigenous fossil-fuel production - Coal'
    t.delete 'Balancing imports - Coal'
    t['Oil'] = sum(t['Indigenous fossil-fuel production - Oil'],t['Balancing imports - Oil'])
    t.delete 'Indigenous fossil-fuel production - Oil'
    t.delete 'Balancing imports - Oil'
    t['Gas'] = sum(t['Indigenous fossil-fuel production - Gas'],t['Balancing imports - Gas'])
    t.delete 'Indigenous fossil-fuel production - Gas'
    t.delete 'Balancing imports - Gas'
    
    # Finance cost
    name          = "Finance cost"
    
    low           = 0 # r("costpercapita_cp#{low_start_row+number_of_components+1}") # Bodge for the zero interest rate at low
    point         = r("costpercapita_cp#{point_start_row+number_of_components+1}")
    high          = r("costpercapita_cp#{high_start_row+number_of_components+1}")
    range         = high - low
    
    finance_low   = 0 # r("costpercapita_cp{low_start_row+i}") # Bodge for the zero interest rate at low
    finance_point = 0
    finance_high  = 0
    finance_range = finance_high - finance_low
    
    t[name] = {low:low,point:point,high:high,range:range,finance_low:finance_low,finance_point:finance_point,finance_high:finance_high,finance_range:finance_range}
  
    pathway['cost_components'] = t
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
  
  CONTROL = (4..55).to_a.map { |r| "control_h#{r}"  } + (4..32).to_a.map { |r| "control_af#{r}" }
  
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
    a << r = g.calculate_pathway(c)
  end
  te = Time.now - t
  puts "#{te/tests} seconds per run"
  puts "#{tests/te} runs per second"
end
