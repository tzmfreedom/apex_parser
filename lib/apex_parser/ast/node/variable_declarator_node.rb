module ApexParser
  module AST
    class VariableDeclaratorNode < Base
      attr_accessor :left, :right

      def accept(visitor)
        visitor.visit_variable_declarator(self)
      end
    end
  end
end
