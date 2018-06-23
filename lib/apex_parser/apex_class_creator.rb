module ApexParser
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
      method = ApexDefMethodNode.new(
        name: name,
        modifiers: [],
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
      method = ApexDefMethodNode.new(
        name: name,
        modifiers: ['static'],
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
        name: @apex_class_name,
        statements: @apex_methods
      )
      ApexClassTable.register(@apex_class.name, @apex_class)
    end
  end
end
