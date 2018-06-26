module ApexParser
  module AST
    class BooleanNode < Base
      attr_accessor :value

      def accept(visitor)
        visitor.visit_boolean(self)
      end
    end
  end
end
