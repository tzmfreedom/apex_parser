module ApexParser
  class ApexClassCreator
    attr_accessor :apex_class_name, :modifiers, :apex_methods

    def initialize
      @apex_methods = []
      @modifiers    = []
      yield(self)
      register
    end

    def add_class(name, modifiers)
      @apex_class_name = name
      @modifiers = modifiers
    end

    def set_constructor(name, modifiers, arguments, &call_proc)
      method = ::ApexParser::AST::ConstructorDeclarationNode.new(
        name: name,
        modifiers: modifiers,
        return_type: :void,
        arguments: arguments.map { |argument| ::ApexParser::AST::ArgumentNode.new(type: argument[0], name: argument[1]) },
        native: true,
        call_proc: call_proc
      )
      @apex_methods << method
    end

    def add_instance_method(name, modifiers, return_type, arguments, &call_proc)
      method = ::ApexParser::AST::MethodDeclarationNode.new(
        name: name,
        modifiers: modifiers,
        return_type: return_type,
        arguments: arguments.map { |argument| ::ApexParser::AST::ArgumentNode.new(type: argument[0], name: argument[1]) },
        native: true,
        call_proc: call_proc
      )
      @apex_methods << method
    end

    def add_static_method(name, modifiers, return_type, arguments, &call_proc)
      method = ::ApexParser::AST::MethodDeclarationNode.new(
        name: name,
        modifiers: modifiers + ['static'],
        return_type: return_type,
        arguments: arguments.map { |argument| ::ApexParser::AST::ArgumentNode.new(type: argument[0], name: argument[1]) },
        native: true,
        call_proc: call_proc
      )
      @apex_methods << method
    end

    def register
      @apex_class = ::ApexParser::ApexClassInitializer.create(
        modifiers: @modifiers,
        name: @apex_class_name,
        statements: @apex_methods,
        apex_super_class: nil,
        implements: nil,
        lineno: nil
      )
      Visitor::Interpreter::ApexClassTable.register(@apex_class.name, @apex_class)
    end
  end
end
