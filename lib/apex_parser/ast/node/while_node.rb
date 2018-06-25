module ApexParser
  module AST
    class WhileNode < Base
      attr_accessor :condition_stmt, :statements

      def accept(visitor, local_scope)
        visitor.visit_while(self, local_scope)
      end
    end
  end
end
