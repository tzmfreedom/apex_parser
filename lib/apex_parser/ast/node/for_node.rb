module ApexParser
  module AST
    class ForNode < Base
      attr_accessor :init_stmt, :exit_condition, :increment_stmt, :statements

      def accept(visitor)
        visitor.visit_for(self)
      end
    end
  end
end
