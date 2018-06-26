module ApexParser
  module AST
    class OperatorNode < Base
      attr_accessor :type, :left, :right

      def accept(visitor)
        visitor.visit_operator(self)
      end
    end
  end
end
