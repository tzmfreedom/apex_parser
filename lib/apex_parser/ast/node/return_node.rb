module ApexParser
  module AST
    class ReturnNode < Base
      attr_accessor :value, :expression

      def accept(visitor)
        visitor.visit_return(self)
      end
    end
  end
end
