module ApexParser
  module AST
    class WhileNode < Base
      attr_accessor :condition_stmt, :statements

      def accept(visitor)
        visitor.visit_while(self)
      end
    end
  end
end
