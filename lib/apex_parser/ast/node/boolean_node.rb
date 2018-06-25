module ApexParser
  module AST
    class BooleanNode < Base
      attr_accessor :value

      def accept(visitor, local_scope)
        visitor.visit_boolean(self, local_scope)
      end
    end
  end
end
