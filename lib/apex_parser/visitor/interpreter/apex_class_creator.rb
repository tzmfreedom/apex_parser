module ApexParser
  class ApexClassCreator
    attr_accessor :apex_class_name, :modifiers, :apex_methods

    def initialize
      yield(self)
      register
    end

    def add_class(name, access_level)
      @apex_class_name = name
      @modifiers = access_level
    end

    def add_instance_method(name, return_type, arguments, &call_proc)
      method = AST::MethodDeclarationNode.new(
        name: name,
        modifiers: [],
        return_type: return_type,
        arguments: arguments.map { |argument| ArgumentNode.new(type: argument[0], name: argument[1]) },
        native: true,
        call_proc: call_proc
      )
      (@apex_methods ||= []) << method
    end

    def add_static_method(name, return_type, arguments, &call_proc)
      method = AST::MethodDeclarationNode.new(
        name: name,
        modifiers: ['static'],
        return_type: return_type,
        arguments: arguments.map { |argument| ArgumentNode.new(type: argument[0], name: argument[1]) },
        call_proc: call_proc
      )
      (@apex_methods ||= []) << method
    end

    def register
      @apex_class = ApexClassNode.new(
        modifiers: @modifiers,
        name: @apex_class_name,
        statements: @apex_methods
      )
      ApexClassTable.register(@apex_class.name, @apex_class)
    end
  end
end
