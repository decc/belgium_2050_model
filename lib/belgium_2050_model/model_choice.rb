class ModelChoice
  
  attr_accessor :number, :name, :type, :descriptions, :long_descriptions
  
  def initialize(number,name,type,descriptions,long_descriptions)
    @number, @name, @type, @descriptions, @long_descriptions = number, name, type, descriptions, long_descriptions
  end
  
  def incremental_or_alternative
    'incremental'
  end
  
  def levels
    if type < 10
      1.upto(type.to_i)
    else
      1.upto(type.to_i/10)
    end
  end

  NUMBER_TO_DOC_MAP = {
  }

  def doc
    "#{NUMBER_TO_DOC_MAP[number] || number}.pdf"
  end
end
