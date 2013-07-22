require_relative '../belgium_2050_model'
require 'singleton'

class ModelStructure < Belgium2050ModelUtilities
  include Singleton
  
  attr_accessor :excel, :choices
    
  def initialize
    @excel = Belgium2050ModelShim.new
    @choices = []
    types.each_with_index do |choice_type,i|
      case choice_type
      when nil, 0.0, 10; next
      when /[abcd]/i; choices << ModelAlternative.new(i,names[i],choice_type,descriptions[i],long_descriptions[i])
      else; choices << ModelChoice.new(i,names[i],choice_type,descriptions[i],long_descriptions[i])
      end
    end
  end
  
  def reported_calculator_version
    excel.control_m1
  end
  
  def controls(col1, col2)
    (4..55).to_a.map { |row| excel.send("control_#{col1}#{row}") } + (4..32).to_a.map { |row| excel.send("control_#{col2}#{row}") }
  end

  def types
    @types ||= controls('p', 'aj')
  end
  
  def names
    @names ||= controls('f', 'z')
  end

  def descriptions
    @descriptions ||= (4..55).to_a.map { |row| [r("control_q#{row}"),r("control_r#{row}"),r("control_s#{row}"),r("control_t#{row}")] } + (4..32).to_a.map { |row| [r("control_ak#{row}"),r("control_al#{row}"),r("control_am#{row}"),r("control_an#{row}")] }
  end

  def long_descriptions
    @long_descriptions ||=  (5..57).to_a.map  { |row| [r("control_bo#{row}"), r("control_bp#{row}"),r("control_bq#{row}"),r("control_br#{row}")] }
  end
    
  def demand_choices
    choices[0..22]
  end

  def industry_choices
    choices[23..43]

  end
  
  def supply_choices
    choices[44..64]
  end

  def example_pathways
    @example_pathways ||= generate_example_pathways
  end
  
  def generate_example_pathways
    %w{ar as at au av aw ax ay az ba}.map do |column|
      code = ((4..55).to_a + (62..90).to_a).map { |row| r("control_#{column}#{row}") }
      {
        name: r("control_#{column}1"),
        code: convert_float_to_letters(code).join,
      }
    end
  end

  # NB: The Belgian calcualtor has some inputs 10..40 rather than 1..4
  def convert_float_to_letters(array)
    array.map.with_index do |entry, i|
      type = types[i]
      entry = 0 if type == nil || type == 0
      entry = (entry / 10.0) if entry && type && type > 4
      case entry
      when nil; 0
      when Float; Belgium2050ModelResult::FLOAT_TO_LETTER_MAP[entry] || entry
      else entry
      end
    end
  end
  
  # FIXME: Only wraps one line into two
  def wrap(string, wrap_at_length = 45)
    return "" unless string
    string = string.to_s
    length_so_far = 0
    string.split.partition do |word| 
      length_so_far = length_so_far + word.length + 1 # +1 for the trailing space 
      length_so_far > wrap_at_length
    end.reverse.map { |a| a.join(" ") }.join("\n")
  end

end
