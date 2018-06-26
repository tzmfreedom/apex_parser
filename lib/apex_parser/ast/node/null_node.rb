module ApexParser
  module AST
    class NullNode < Base
      def initialize; end

      def accept(visitor)
        visitor.visit_null(self)
      end

      def value
        nil
      end
    end
  end
end
