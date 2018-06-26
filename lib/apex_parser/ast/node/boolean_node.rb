module ApexParser
  module AST
    class BooleanNode < SingleValueNode
      def accept(visitor)
        visitor.visit_boolean(self)
      end
    end
  end
end
