class ApexModel
  def initialize(args = {})
    self.class.attributes.each do |attr|
      instance_variable_set("@#{attr}", args[attr])
    end
  end

  def inspect
    self.class.attributes.map { |attr| "#{attr} => #{send(attr)}" }
  end

  class << self
    attr_accessor :attributes

    def attr_accessor(*args)
      (@attributes ||= []).concat(args)
      super
    end
  end
end

class ApexClass < ApexModel
  attr_accessor :access_level, :name, :statements, :apex_instance_variables, :apex_instance_methods

  def initialize(args = {})
    super
    @apex_instance_methods = {}
    @apex_instance_variables = {}

    statements.each do |statement|
      statement.add_to_class(self)
    end
  end

  def call(method_name, arguments, local_scope)
    # argumentsをlocal_scopeで評価
    apex_instance_methods[method_name.to_sym].call(arguments)
  end
end

# LocalScope
class ApexMethod < ApexModel
  attr_accessor :name, :access_level, :return_type, :arguments, :statements

  def add_to_class(klass)
    klass.apex_instance_methods[name.to_sym] = self
  end

  def call(arguments, local_scope = {})
    local_scope[:arg1] = arguments[0]
    statements.each do |statement|
      statement.call(local_scope)
    end
  end
end

class InstanceVariable < ApexModel
  attr_accessor :type, :name, :access_level, :expression

  def add_to_class(klass)
    klass.apex_instance_variables[name.to_sym] = self
  end
end

class Statement < ApexModel
  attr_accessor :type, :receiver, :method_name, :arguments

  def call(local_scope)
    case type
      when :call
        if receiver.respond_to?(:call)
          receiver.call(method_name, arguments, local_scope)
        else
          ApexClassTable[receiver].call(method_name, arguments, local_scope)
        end
    end
  end
end

class ApexObject < ApexModel
  attr_accessor :apex_class, :instance_variables
end

class ApexInteger < ApexModel
  attr_accessor :value

  def call
    value
  end
end

class ApexDouble < ApexModel
  attr_accessor :value

  def eval
    value
  end
end


class LocalScope
  attr_accessor :variables
end

class ApexClassTable
  attr_accessor :apex_classes

  class << self
    def register(name, apex_class)
      (@apex_classes ||= {})[name.to_sym] = apex_class
    end

    def [](name)
      @apex_classes[name.to_sym]
    end
  end
end

method_statements = [-> (args) { puts args[:arg1] }]

statements = [
  ApexMethod.new(
    name: 'debug',
    access_level: :public,
    return_type: :void,
    arguments: [],
    statements: method_statements
  )
]
system = ApexClass.new(access_level: :public, name: 'System', statements: statements)
ApexClassTable.register(:System, system)