module ApexParser
  class SingleValueNode
    attr_accessor :value

    def initialize(value)
      @value = value
    end
  end

  class Base
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

  class ApexClassNode < Base
    attr_accessor :name, :statements, :modifiers,
                  :apex_super_class, :implements,
                  :apex_instance_variables, :apex_instance_methods,
                  :apex_static_variables, :apex_static_methods

    def initialize(args = {})
      super
      @statements ||= []
      @implements ||= []
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

  class ApexDefMethodNode < Base
    attr_accessor :name, :modifiers, :return_type,
                  :arguments, :statements, :apex_class_name,
                  :modifiers

    def native?
      false
    end

    def add_to_class(klass)
      self.apex_class_name = klass.name
      if modifiers && modifiers.include?('static')
        klass.apex_static_methods[name] = self
      else
        klass.apex_instance_methods[name] = self
      end
    end

    def accept(visitor, local_scope)
      visitor.visit_method(self, local_scope)
    end
  end

  class ApexStaticVariableNode < Base
    attr_accessor :type, :name, :modifiers, :expression

    def add_to_class(klass)
      klass.apex_static_variables[name] = self
    end

    def accept(visitor)
      visitor.visit_static_variable(self)
    end
  end

  class InstanceVariableNode < Base
    attr_accessor :receiver, :name

    def accept(visitor, local_scope)
      visitor.visit_instance_variable(self, local_scope)
    end
  end

  class DefInstanceVariableNode < Base
    attr_accessor :type, :name, :modifiers, :expression, :apex_class_node

    def add_to_class(klass)
      self.apex_class_node = klass
      klass.apex_instance_variables[name] = self
    end

    def accept(visitor, local_scope)
      visitor.visit_def_instance_variable(self, local_scope)
    end
  end

  class IfNode < Base
    attr_accessor :condition, :if_stmt, :else_stmt

    def accept(visitor, local_scope)
      visitor.visit_if(self, local_scope)
    end
  end

  class ArgumentNode < Base
    attr_accessor :type, :name

    def initialize(*args)
      super

      self.type =
        case type.to_sym
          when :Integer
            ApexIntegerNode
          when :Double
            ApexDoubleNode
          when :Boolean
            BooleanNode
          when :String
            ApexStringNode
          when :Object
            AnyObject
          else
            ApexObjectNode
        end
    end
  end

  class ForNode < Base
    attr_accessor :init_stmt, :exit_condition, :increment_stmt, :statements

    def accept(visitor, local_scope)
      visitor.visit_for(self, local_scope)
    end
  end

  class WhileNode < Base
    attr_accessor :condition_stmt, :statements

    def accept(visitor, local_scope)
      visitor.visit_while(self, local_scope)
    end
  end

  class ForEnumNode < Base
    attr_accessor :type, :ident, :list, :statements

    def accept(visitor, local_scope)
      visitor.visit_forenum(self, local_scope)
    end
  end

  class IdentifyNode < Base
    attr_accessor :name

    def accept(visitor, local_scope)
      visitor.visit_identify(self, local_scope)
    end
  end

  class BooleanNode < SingleValueNode
    def accept(visitor, local_scope)
      visitor.visit_boolean(self, local_scope)
    end
  end

  class ApexStringNode < SingleValueNode
    def accept(visitor, local_scope)
      visitor.visit_string(self, local_scope)
    end
  end

  class ApexObjectNode < Base
    attr_accessor :apex_class_node, :arguments, :apex_instance_variables, :generics_node

    def accept(visitor, local_scope)
      visitor.visit_object(self, local_scope)
    end

    def value
      "#<#{apex_class_node.name}#{generics_node ? "<#{generics_node.name}>" : nil}:#{object_id}>"
    end
  end

  class CommentNode < SingleValueNode
    def add_to_class(klass); end

    def accept(visitor, local_scope)
      nil
    end
  end

  class NullNode < Base
    def initialize; end

    def accept(visitor, local_scope)
      visitor.visit_null(self, local_scope)
    end

    def value
      nil
    end
  end

  class ApexIntegerNode < SingleValueNode
    def accept(visitor, local_scope)
      visitor.visit_integer(self, local_scope)
    end
  end

  class ApexDoubleNode < SingleValueNode
    def accept(visitor, local_scope)
      visitor.visit_double(self, local_scope)
    end
  end

  class NewNode < Base
    attr_accessor :apex_class_name, :arguments

    def initialize(*args)
      super

      @arguments ||= []
    end

    def accept(visitor, local_scope)
      visitor.visit_new(self, local_scope)
    end
  end

  class SoqlNode < Base
    attr_accessor :soql

    def accept(visitor, local_scope)
      visitor.visit_soql(self, local_scope)
    end

    def value
      soql
    end
  end

  class ReturnNode < Base
    attr_accessor :value, :expression

    def accept(visitor, local_scope)
      visitor.visit_return(self, local_scope)
    end
  end

  class BreakNode < Base
  end

  class ContinueNode < Base
  end

  class ApexClassTable
    attr_accessor :apex_classes

    class << self
      def register(name, apex_class)
        (@apex_classes ||= HashWithUpperCasedSymbolicKey.new)[name] = apex_class
      end

      def [](name)
        @apex_classes[name]
      end
    end
  end

  class AnnotationNode < Base
    attr_accessor :name

    def initialize(name)
      @name = name
    end

    def accept(visitor, local_scope)
      visitor.visit_annotation(self, local_scope)
    end
  end

  class CallMethodNode < Base
    attr_accessor :receiver, :arguments, :apex_method_name

    def initialize(*args)
      super
      @arguments ||= []
    end

    def accept(visitor, local_scope)
      visitor.visit_call_method(self, local_scope)
    end
  end

  class OperatorNode < Base
    attr_accessor :type, :left, :operator, :right

    def accept(visitor, local_scope)
      visitor.visit_operator(self, local_scope)
    end
  end

  class AnyObject; end

  class SObject
    attr_accessor :attributes

    def initialize(attributes = {})
      @attributes = attributes
    end

    def value
      inspect
    end
  end
end
