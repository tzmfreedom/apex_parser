module ApexParser
  module AST
    class OperatorNode < Base
      attr_accessor :type, :left, :operator, :right

      def accept(visitor, local_scope)
        visitor.visit_operator(self, local_scope)
      end
    end
  end
end
