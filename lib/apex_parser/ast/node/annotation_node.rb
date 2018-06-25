module ApexParser
  module AST
    class AnnotationNode < Base
      attr_accessor :name

      def initialize(name)
        @name = name
      end

      def accept(visitor, local_scope)
        visitor.visit_annotation(self, local_scope)
      end
    end
  end
end
