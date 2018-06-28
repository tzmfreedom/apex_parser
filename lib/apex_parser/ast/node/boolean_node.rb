module ApexParser
  module AST
    class BooleanNode < SingleValueNode

      def apex_class_node
        ApexClassTable[:Boolean][:_top]
      end

      def accept(visitor)
        visitor.visit_boolean(self)
      end
    end
  end
end
