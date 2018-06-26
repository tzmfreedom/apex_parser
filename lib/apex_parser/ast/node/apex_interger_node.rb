module ApexParser
  module AST
    class ApexIntegerNode < Base
      attr_accessor :value

      def accept(visitor)
        visitor.visit_integer(self)
      end
    end
  end
end
