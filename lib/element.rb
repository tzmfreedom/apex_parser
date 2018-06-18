class ApexClass
  attr_accessor :modifier, :static_variables, :instance_methods, :class_methods
end

class ApexObject
  attr_accessor :apex_class, :instance_variables
end

class ApexInteger
  attr_accessor :value

  def eval
    value
  end
end

class ApexDouble
  attr_accessor :value

  def eval
    value
  end
end

class ApexMethod
  attr_accessor :name, :modifier, :return_type, :arguments

  def eval(*args)
    puts args
  end
end

class ApexClassTable
  attr_accessor :apex_classes

  class << self
    def add_register(name, apex_class)
      (@apex_classes ||= {})[name.to_sym] = apex_class
    end

    def [](name)
      @apex_classes[name.to_sym]
    end
  end
end

klass = ApexClass.new
klass.instance_methods = {}
klass.instance_methods[:debug] = ApexMethod.new
ApexClassTable.add_register(:System, klass)