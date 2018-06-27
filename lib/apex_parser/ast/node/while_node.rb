module ApexParser
  module AST
    class WhileNode < Base
      attr_accessor :condition_statement, :statements

      def accept(visitor)
        visitor.visit_while(self)
      end
    end
  end
end
