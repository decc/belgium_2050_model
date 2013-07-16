class Belgium2050ModelUtilities
  def get_array(references)
    references.map do |reference|
      r(reference)
    end
  end
  
  def r(reference)
    excel.send(reference)
  end
  
  def set_array(references, values)
    values.each_with_index do |v,i|
      ref = "#{references[i]}="
      excel.send(ref,v)
    end
  end
  
  def reset
    excel.reset
  end
end
