module ApexParser
  module AST
    class NullNode < Base
      def initialize; end

      def accept(visitor, local_scope)
        visitor.visit_null(self, local_scope)
      end

      def value
        nil
      end
    end
  end
end
