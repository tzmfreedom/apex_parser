module ApexParser
  module AST
    class IfNode < Base
      attr_accessor :condition, :if_stmt, :else_stmt

      def accept(visitor)
        visitor.visit_if(self)
      end
    end
  end
end
