
class ApexNode
  attr_accessor :lineno

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

class ApexClassNode < ApexNode
  attr_accessor :access_level, :name, :statements,
                :apex_instance_variables, :apex_instance_methods,
                :apex_static_variables, :apex_static_methods

  def initialize(args = {})
    super
    @apex_instance_methods = {}
    @apex_static_methods = {}
    @apex_static_variables = {}
    @apex_instance_variables = {}

    statements.each do |statement|
      statement.add_to_class(self)
    end
  end

  def accept(visitor)
    visitor.visit_class(self)
  end
end

class ApexStaticMethodNode < ApexNode
  attr_accessor :name, :access_level, :return_type,
                :arguments, :statements, :apex_class_name

  def native?
    false
  end

  def add_to_class(klass)
    self.apex_class_name = klass.name
    klass.apex_static_methods[name.to_sym] = self
  end

  def accept(visitor)
    visitor.visit_class_method(self)
  end
end

class ApexInstanceMethodNode < ApexNode
  attr_accessor :name, :access_level, :return_type,
                :arguments, :statements, :apex_class_name

  def add_to_class(klass)
    self.apex_class_name = klass.name
    klass.apex_instance_methods[name.to_sym] = self
  end

  def accept(visitor)
    visitor.visit_method(self)
  end
end

class ApexStaticVariableNode < ApexNode
  attr_accessor :type, :name, :access_level, :expression

  def add_to_class(klass)
    klass.apex_static_variables[name.to_sym] = self
  end

  def accept(visitor)
    visitor.visit_static_variable(self)
  end
end

class InstanceVariableNode < ApexNode
  attr_accessor :type, :name, :access_level, :expression

  def add_to_class(klass)
    klass.apex_instance_variables[name.to_sym] = self
  end

  def accept(visitor)
    visitor.visit_instance_variable(self)
  end
end

class IfNode < ApexNode
  attr_accessor :condition, :if_stmt, :else_stmt

  def accept(visitor, local_scope)
    visitor.visit_if(self, local_scope)
  end
end

class IdentifyNode < ApexNode
  attr_accessor :name

  def accept(visitor, local_scope)
    visitor.visit_identify(self, local_scope)
  end
end

class BooleanNode < ApexNode
  attr_accessor :value

  def initialize(value)
    @value = value
  end

  def accept(visitor, local_scope)
    visitor.visit_boolean(self, local_scope)
  end
end

class ApexStringNode < ApexNode
  attr_accessor :value

  def accept(visitor, local_scope)
    visitor.visit_string(self, local_scope)
  end
end

class ApexObjectNode < ApexNode
  attr_accessor :apex_class, :instance_variables

  def accept(visitor, local_scope)
    visitor.visit_object(self, local_scope)
  end
end

class ApexIntegerNode < ApexNode
  attr_accessor :value

  def accept(visitor, local_scope)
    visitor.visit_integer(self, local_scope)
  end
end

class ApexDoubleNode < ApexNode
  attr_accessor :value

  def accept(visitor, local_scope)
    visitor.visit_double(self, local_scope)
  end
end


class Environment
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

class ApexClassCreatetor
  attr_accessor :apex_class_name, :apex_class_access_level, :apex_methods

  def add_class(name, access_level)
    @apex_class_name = name
    @apex_class_access_level = access_level
  end

  def add_method(name, access_level, return_type, &block)
    method = ApexStaticMethodNode.new(
      name: name,
      access_level: access_level,
      return_type: return_type,
      arguments: [],
    )
    method.instance_eval do
      define_singleton_method(:native?) do
        true
      end

      define_singleton_method(:call) do |local_scope|
        block.call(local_scope)
      end
    end
    (@apex_methods ||= []) << method
  end

  def register
    @apex_class = ApexClassNode.new(access_level: @apex_class_access_level, name: @apex_class_name, statements: @apex_methods)
    ApexClassTable.register(@apex_class.name, @apex_class)
  end
end

creator = ApexClassCreatetor.new
creator.add_class(:System, :public)
creator.add_method(:debug, :public, :String) do |local_scope|
  puts local_scope[:arg1].value
end
creator.register
