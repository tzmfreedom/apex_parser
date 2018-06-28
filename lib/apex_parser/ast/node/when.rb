module ApexParser
  module AST
    class When < Base
      attr_accessor :condition, :statements

      def accept(visitor)
        visitor.visit_when(self)
      end
    end
  end
end
