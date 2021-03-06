module ApexParser
  module AST
    class ObjectNode < Base
      attr_accessor :apex_class_node, :arguments, :instance_fields, :generics_arguments

      def accept(visitor)
        visitor.visit_object(self)
      end

      def value
        "#<#{apex_class_node.name}#{generics_arguments ? "<#{generics_arguments.map(&:name).join(', ')}>" : nil}:#{object_id}>"
      end
    end
  end
end
