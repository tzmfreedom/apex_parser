class ApexNode
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
    evaluated_arguments = arguments.map { |argument|
      argument.call(local_scope)
    }
    apex_instance_methods[method_name.to_sym].call(evaluated_arguments)
  end
end

class ApexMethodNode < ApexNode
  attr_accessor :name, :access_level, :return_type, :arguments, :statements

  def add_to_class(klass)
    klass.apex_instance_methods[name.to_sym] = self
  end

  def call(arguments, local_scope = {})
    local_scope[:arg1] = arguments[0]
    execute(local_scope)
  end

  private

  def execute(local_scope)
    statements.each do |statement|
      statement.call(local_scope)
    end
  end
end

class InstanceVariableNode < ApexNode
  attr_accessor :type, :name, :access_level, :expression

  def add_to_class(klass)
    klass.apex_instance_variables[name.to_sym] = self
  end
end

class StatementNode < ApexNode
  attr_accessor :type, :receiver, :name, :method_name, :arguments, :expression

  def call(local_scope)
    case type
      when :call
        if receiver.respond_to?(:call)
          receiver.call(method_name, arguments, local_scope)
        else
          ApexClassTable[receiver].call(method_name, arguments, local_scope)
        end
      when :assign
        local_scope[name.to_sym] = expression.call(local_scope)
      when :define
        if expression
          local_scope[name.to_sym] = expression.call(local_scope)
        else
          local_scope[name.to_sym] = nil
        end
    end
  end
end

class IdentifyNode < ApexNode
  attr_accessor :name

  def call(local_scope)
    local_scope[name.to_sym]
  end
end

class ApexStringNode < ApexNode
  attr_accessor :value

  def call(_)
    value
  end
end

class ApexObjectNode < ApexNode
  attr_accessor :apex_class, :instance_variables
end

class ApexIntegerNode < ApexNode
  attr_accessor :value

  def call(_)
    value
  end
end

class ApexDoubleNode < ApexNode
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

class ApexClassCreatetor
  attr_accessor :apex_class_name, :apex_class_access_level, :apex_methods

  def add_class(name, access_level)
    @apex_class_name = name
    @apex_class_access_level = access_level
  end

  def add_method(name, access_level, return_type, &block)
    method = ApexMethodNode.new(
      name: name,
      access_level: access_level,
      return_type: return_type,
      arguments: [],
    )
    method.instance_eval do
      define_singleton_method(:execute) do |local_scope|
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
  puts local_scope[:arg1]
end
creator.register
