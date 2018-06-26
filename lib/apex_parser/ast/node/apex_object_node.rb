module ApexParser
  module AST
    class ObjectNode < Base
      def accept(visitor)
        visitor.visit_object(self)
      end
    end
  end
end
