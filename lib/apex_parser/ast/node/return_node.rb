module ApexParser
  module AST
    class ReturnNode < Base
      attr_accessor :value, :expression

      def accept(visitor, local_scope)
        visitor.visit_return(self, local_scope)
      end
    end
  end
end
