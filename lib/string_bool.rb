class String
  def to_bool
    return true if self =~ (/^(true|t|yes|y|1)$/i)
    return false if self.empty? || self =~ (/^(false|f|no|n|0)$/i)

    return false
  end
end

class NilClass
  def to_bool
    return false
  end
end

class TrueClass
  def to_bool
    return true
  end
end

class FalseClass
  def to_bool
    return false
  end
end
