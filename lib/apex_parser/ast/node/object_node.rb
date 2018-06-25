module ApexParser
  module AST
    class ObjectNode < Base
      attr_accessor :apex_class_node, :arguments, :apex_instance_variables, :generics_node

      def accept(visitor, local_scope)
        visitor.visit_object(self, local_scope)
      end

      def value
        "#<#{apex_class_node.name}#{generics_node ? "<#{generics_node.name}>" : nil}:#{object_id}>"
      end
    end
  end
end
