module ApexParser
  module AST
    class ApexStringNode < Base
      attr_accessor :value

      def apex_class_node
        ApexClassTable[:String][:_top]
      end

      def accept(visitor)
        visitor.visit_string(self)
      end
    end
  end
end
