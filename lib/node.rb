class HashWithUpperCasedSymbolicKey
  attr_accessor :env

  def initialize(init_hash = {})
    @env = {}
    init_hash.map { |k, v| @env[k.upcase.to_sym] = v }
  end

  def []=(key, value)
    @env[key.upcase.to_sym] = value
  end

  def [](key)
    @env[key.upcase.to_sym]
  end

  def map(&block)
    @env.map(&block)
  end
end

class ApexNode
  attr_accessor :lineno

  def initialize(args = {})
    self.class.attributes.each do |attr|
      public_send("#{attr}=", args[attr])
    end
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
    @apex_instance_methods = HashWithUpperCasedSymbolicKey.new
    @apex_static_methods = HashWithUpperCasedSymbolicKey.new
    @apex_static_variables = HashWithUpperCasedSymbolicKey.new
    @apex_instance_variables = HashWithUpperCasedSymbolicKey.new

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
    klass.apex_static_methods[name.name] = self
  end

  def accept(visitor)
    visitor.visit_class_method(self)
  end
end

class ApexDefInstanceMethodNode < ApexNode
  attr_accessor :name, :access_level, :return_type,
                :arguments, :statements, :apex_class_name

  def native?
    false
  end

  def add_to_class(klass)
    self.apex_class_name = klass.name
    klass.apex_instance_methods[name.name] = self
  end

  def accept(visitor, local_scope)
    visitor.visit_method(self, local_scope)
  end
end

class ApexStaticVariableNode < ApexNode
  attr_accessor :type, :name, :access_level, :expression

  def add_to_class(klass)
    klass.apex_static_variables[name.name] = self
  end

  def accept(visitor)
    visitor.visit_static_variable(self)
  end
end

class InstanceVariableNode < ApexNode
  attr_accessor :receiver, :name

  def accept(visitor, local_scope)
    visitor.visit_instance_variable(self, local_scope)
  end
end

class DefInstanceVariableNode < ApexNode
  attr_accessor :type, :name, :access_level, :expression, :apex_class_node

  def add_to_class(klass)
    self.apex_class_node = klass
    klass.apex_instance_variables[name.name] = self
  end

  def accept(visitor, local_scope)
    visitor.visit_def_instance_variable(self, local_scope)
  end
end

class IfNode < ApexNode
  attr_accessor :condition, :if_stmt, :else_stmt

  def accept(visitor, local_scope)
    visitor.visit_if(self, local_scope)
  end
end

class ArgumentNode < ApexNode
  attr_accessor :type, :name

  def initialize(*args)
    super

    self.type =
      case type
      when :Integer
        ApexIntegerNode
      when :Double
        ApexDoubleNode
      when :Boolean
        ApexBooleanNode
      when :String
        ApexStringNode
      when :Object
        AnyObject
      else
        ApexObjectNode
      end
  end
end

class ForNode < ApexNode
  attr_accessor :init_stmt, :exit_condition, :increment_stmt, :statements

  def accept(visitor, local_scope)
    visitor.visit_for(self, local_scope)
  end
end

class WhileNode < ApexNode
  attr_accessor :condition_stmt, :statements

  def accept(visitor, local_scope)
    visitor.visit_while(self, local_scope)
  end
end

class ForEnumNode < ApexNode
  attr_accessor :type, :ident, :list, :statements

  def accept(visitor, local_scope)
    visitor.visit_forenum(self, local_scope)
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
  attr_accessor :apex_class_node, :arguments, :apex_instance_variables

  def accept(visitor, local_scope)
    visitor.visit_object(self, local_scope)
  end

  def value
    "#<#{apex_class_node.name.name}:#{object_id}>"
  end
end

class NullNode < ApexNode
  def initialize; end

  def accept(visitor, local_scope)
    visitor.visit_null(self, local_scope)
  end

  def value
    nil
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

class NewNode < ApexNode
  attr_accessor :apex_class_name, :arguments

  def initialize(*args)
    super

    @arguments ||= []
  end

  def accept(visitor, local_scope)
    visitor.visit_new(self, local_scope)
  end
end

class SoqlNode < ApexNode
  attr_accessor :soql

  def accept(visitor, local_scope)
    visitor.visit_soql(self, local_scope)
  end

  def value
    soql
  end
end

class ReturnNode < ApexNode
  attr_accessor :value, :expression

  def accept(visitor, local_scope)
    visitor.visit_return(self, local_scope)
  end
end

class BreakNode < ApexNode
end

class ContinueNode < ApexNode
end

class ApexClassTable
  attr_accessor :apex_classes

  class << self
    def register(name, apex_class)
      (@apex_classes ||= HashWithUpperCasedSymbolicKey.new)[name.name] = apex_class
    end

    def [](name)
      @apex_classes[name.name]
    end
  end
end

class AnnotationNode < ApexNode
  attr_accessor :name

  def initialize(name)
    @name = name
  end

  def accept(visitor, local_scope)
    visitor.visit_annotation(self, local_scope)
  end
end

class CallMethodNode < ApexNode
  attr_accessor :receiver, :arguments, :apex_method_name

  def initialize(*args)
    super
    @arguments ||= []
  end

  def accept(visitor, local_scope)
    visitor.visit_call_method(self, local_scope)
  end
end

class OperatorNode < ApexNode
  attr_accessor :type, :left, :operator, :right

  def accept(visitor, local_scope)
    visitor.visit_operator(self, local_scope)
  end
end

class AnyObject; end

class ApexClassCreator
  attr_accessor :apex_class_name, :apex_class_access_level, :apex_methods

  def initialize
    yield(self)
    register
  end

  def add_class(name, access_level)
    @apex_class_name = name
    @apex_class_access_level = access_level
  end

  def add_instance_method(name, access_level, return_type, arguments, &block)
    method = ApexDefInstanceMethodNode.new(
      name: IdentifyNode.new(name: name),
      access_level: access_level,
      return_type: return_type,
      arguments: arguments.map { |argument| ArgumentNode.new(type: argument[0], name: argument[1]) },
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

  def add_static_method(name, access_level, return_type, arguments, &block)
    method = ApexStaticMethodNode.new(
      name: IdentifyNode.new(name: name),
      access_level: access_level,
      return_type: return_type,
      arguments: arguments.map { |argument| ArgumentNode.new(type: argument[0], name: argument[1]) },
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
    @apex_class = ApexClassNode.new(
      access_level: @apex_class_access_level,
      name: IdentifyNode.new(name: @apex_class_name),
      statements: @apex_methods
    )
    ApexClassTable.register(@apex_class.name, @apex_class)
  end
end

ApexClassCreator.new do |c|
  c.add_class(:System, :public)
  c.add_static_method(:debug, :public, :String, [[:Object, :object]]) do |local_scope|
    puts local_scope[:object].value
  end
end

ApexClassCreator.new do |c|
  c.add_class(:List, :public)
  c.add_instance_method(:List, :public, :void, []) do |local_scope|
    this = local_scope[:this]
    this.apex_instance_variables[:records] = [ApexIntegerNode.new(value: 1001), ApexIntegerNode.new(value: 2001)]
  end
  c.add_instance_method(:next, :public, :Account, []) do |local_scope|
    this = local_scope[:this]
    idx = this.apex_instance_variables[:_idx] ||= 0
    this.apex_instance_variables[:_idx] += 1
    this.apex_instance_variables[:records][idx]
  end
  c.add_instance_method(:has_next, :public, :Boolean, []) do |local_scope|
    this = local_scope[:this]
    this.apex_instance_variables[:records]
    idx = this.apex_instance_variables[:_idx] ||= 0
    BooleanNode.new(idx < this.apex_instance_variables[:records].length)
  end
end
