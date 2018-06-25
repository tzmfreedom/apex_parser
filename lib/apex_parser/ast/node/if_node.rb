module ApexParser
  module AST
    class IfNode < Base
      attr_accessor :condition, :if_stmt, :else_stmt

      def accept(visitor, local_scope)
        visitor.visit_if(self, local_scope)
      end
    end
  end
end
