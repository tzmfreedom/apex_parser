require_relative './method_declaration_node'

module ApexParser
  module AST
    class ConstructorDeclarationNode < MethodDeclarationNode
      attr_accessor :name, :modifiers, :return_type,
                    :arguments, :statements, :native, :call_proc
    end
  end
end
