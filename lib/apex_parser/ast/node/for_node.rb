module ApexParser
  module AST
    class ForNode < Base
      attr_accessor :init_statement, :exit_condition, :increment_statement, :statements

      def accept(visitor)
        visitor.visit_for(self)
      end
    end
  end
end
