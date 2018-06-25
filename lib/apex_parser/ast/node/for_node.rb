module ApexParser
  module AST
    class ForNode < Base
      attr_accessor :init_stmt, :exit_condition, :increment_stmt, :statements

      def accept(visitor, local_scope)
        visitor.visit_for(self, local_scope)
      end
    end
  end
end
