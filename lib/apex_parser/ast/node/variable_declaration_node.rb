module ApexParser
  module AST
    class VariableDeclarationNode < Base
      attr_accessor :type, :statements

      def accept(visitor)
        visitor.visit_variable_declaration(self)
      end
    end
  end
end
