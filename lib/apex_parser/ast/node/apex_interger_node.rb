module ApexParser
  module AST
    class ApexIntegerNode < Base
      attr_accessor :value

      def apex_class_node
        ApexClassTable[:Integer][:_top]
      end

      def accept(visitor)
        visitor.visit_integer(self)
      end
    end
  end
end
