module ApexParser
  module AST
    class ApexIntegerNode < Base
      attr_accessor :value

      def accept(visitor, local_scope)
        visitor.visit_integer(self, local_scope)
      end
    end
  end
end
